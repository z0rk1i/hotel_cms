class Booking < ApplicationRecord
  include ConstraintGuarded
  include StatusNotifiable
  include StatusTransitionable

  guard_constraint_error :room, "уже забронирован на выбранные даты"

  belongs_to :guest
  belongs_to :room
  belongs_to :user, optional: true

  has_many :service_orders, dependent: :restrict_with_error
  has_many :audit_logs, class_name: "BookingAuditLog", dependent: :destroy

  enum :status, { pending: "pending", confirmed: "confirmed", checked_in: "checked_in", checked_out: "checked_out", cancelled: "cancelled" }

  transitions_for(
    pending: %i[confirmed cancelled],
    confirmed: %i[checked_in cancelled],
    checked_in: %i[checked_out cancelled],
    checked_out: [],
    cancelled: []
  )

  validates :check_in, presence: true
  validates :check_out, presence: true
  validates :guests_count, numericality: { only_integer: true, greater_than_or_equal_to: 1 }, allow_nil: true
  validate :check_out_after_check_in
  validate :no_date_overlap
  validate :capacity_within_limit
  validate :room_bookable

  before_validation :set_defaults, on: :create
  before_save :calculate_total_price, if: -> { room && check_in && check_out && (new_record? || room_id_changed? || check_in_changed? || check_out_changed?) }

  after_save :sync_room_status, if: -> { saved_change_to_status? }
  after_save :cancel_pending_service_orders, if: -> { saved_change_to_status? && cancelled? }
  after_save :audit_status_change, if: -> { saved_change_to_status? }
  before_destroy :free_room, if: -> { checked_in? }

  after_commit :deliver_created_email, on: :create
  after_update :deliver_status_email, if: -> { saved_change_to_status? }
  after_commit :notify_admins_of_new_booking, on: :create

  scope :active, -> { where.not(status: :cancelled) }
  scope :occupying, -> { where(status: %i[confirmed checked_in]) }
  scope :active_for_service, -> { occupying.order(:check_in) }
  scope :overlapping, ->(start_date, end_date) { where("check_in < ? AND check_out > ?", end_date, start_date) }
  scope :occupying_overlapping, ->(start_date, end_date) { occupying.overlapping(start_date, end_date) }
  scope :upcoming, -> { active.where("check_in >= ?", Date.current).order(:check_in) }
  scope :checked_in_now, -> { where(status: :checked_in) }
  scope :active_overlapping, ->(start_date, end_date) { active.overlapping(start_date, end_date) }
  scope :for_period, ->(from, to) { where("check_in < ? AND check_out > ?", to, from) }
  scope :by_month, ->(date) { where("check_in >= ? AND check_in <= ?", date.beginning_of_month, date.end_of_month) }

  def nights
    (check_out - check_in).to_i
  end

  def booking_option_label
    "№#{id} · номер #{room.number} · #{I18n.l(check_in, format: :long)} — #{I18n.l(check_out, format: :long)}"
  end

  def self.status_labels
    {
      "pending" => "ожидает подтверждения",
      "confirmed" => "подтверждена",
      "checked_in" => "гость заселён",
      "checked_out" => "гость выселен",
      "cancelled" => "отменена"
    }
  end

  private

  def set_defaults
    self.status ||= :pending
  end

  def check_out_after_check_in
    return if check_in.blank? || check_out.blank?

    errors.add(:check_out, "должна быть позже даты заезда") if check_out <= check_in
  end

  def no_date_overlap
    return if cancelled?
    return if room.blank? || check_in.blank? || check_out.blank?

    errors.add(:room, "уже забронирован на выбранные даты") if room.occupied_during?(check_in, check_out, exclude_booking: self)
  end

  def capacity_within_limit
    return if room.blank? || guests_count.nil?

    errors.add(:guests_count, "превышает вместимость номера") if guests_count > room.capacity
  end

  def room_bookable
    return if room.blank?

    errors.add(:room, "недоступен для бронирования") if room.maintenance? || room.cleaning?
    return if check_in.blank? || check_out.blank?

    errors.add(:room, "недоступен для бронирования на выбранные даты") if room.unavailable_during?(check_in, check_out)
  end

  def calculate_total_price
    self.total_price = nights * room.price_per_night
  end

  def sync_room_status
    if checked_in?
      room.update_column(:status, :occupied) unless room.occupied?
    elsif status_before_last_save == "checked_in"
      room.update_column(:status, :available) if room.occupied?
    end
  end

  def free_room
    room.update_column(:status, :available) if room.occupied?
  end

  def cancel_pending_service_orders
    service_orders.pending.each { |order| order.transition_to(:cancelled) }
  end

  def audit_status_change
    BookingAuditLog.create(
      booking: self,
      administrator: Thread.current[:current_administrator],
      from_status: status_before_last_save,
      to_status: status
    )
  end

  def deliver_created_email
    return unless email_deliverable?

    BookingMailer.created(self).deliver_later
  end

  def deliver_status_email
    return unless email_deliverable?

    case status
    when "confirmed" then BookingMailer.confirmed(self).deliver_later
    when "cancelled" then BookingMailer.cancelled(self).deliver_later
    end
  end

  def email_deliverable?
    user&.email_deliverable?
  end

  def notify_admins_of_new_booking
    AdminMailer.new_booking(self).deliver_later if Administrator.exists?
  end

  def notification_kind
    "booking_status"
  end

  def notification_title
    "Статус брони №#{id} изменён"
  end

  def notification_body
    "Бронь «номер #{room.number}» (#{I18n.l(check_in, format: :long)} — #{I18n.l(check_out, format: :long)}) — #{self.class.status_labels.fetch(status.to_s, status)}."
  end
end
