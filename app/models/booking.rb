class Booking < ApplicationRecord
  belongs_to :guest
  belongs_to :room

  enum :status, { pending: "pending", confirmed: "confirmed", checked_in: "checked_in", checked_out: "checked_out", cancelled: "cancelled" }

  validates :check_in, presence: true
  validates :check_out, presence: true
  validate :check_out_after_check_in
  validate :no_date_overlap
  validate :capacity_within_limit

  before_validation :set_defaults, on: :create
  before_save :calculate_total_price, if: -> { room && check_in && check_out }

  scope :active, -> { where.not(status: :cancelled) }
  scope :upcoming, -> { active.where("check_in >= ?", Date.current).order(:check_in) }
  scope :checked_in_now, -> { where(status: :checked_in) }
  scope :active_overlapping, ->(start_date, end_date) do
    active.where("check_in < ? AND check_out > ?", end_date, start_date)
  end
  scope :for_period, ->(from, to) { where("check_in < ? AND check_out > ?", to, from) }
  scope :by_month, ->(date) { where("check_in >= ? AND check_in <= ?", date.beginning_of_month, date.end_of_month) }

  def nights
    (check_out - check_in).to_i
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

  def calculate_total_price
    self.total_price = nights * room.price_per_night
  end
end
