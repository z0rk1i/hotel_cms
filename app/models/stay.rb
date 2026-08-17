class Stay < ApplicationRecord
  PAYMENT_METHODS = %w[cash card transfer].freeze
  TRANSITIONS = {
    "pending" => %w[confirmed cancelled],
    "confirmed" => %w[checked_in cancelled],
    "checked_in" => %w[checked_out cancelled]
  }.freeze

  belongs_to :room
  belongs_to :user

  validates :check_in, :check_out, presence: true
  validates :status, inclusion: { in: %w[pending confirmed checked_in checked_out cancelled] }
  validates :guests_count, numericality: { only_integer: true, greater_than: 0 }
  validate :dates_are_ordered
  validate :no_overlap
  validate :capacity_within_room
  validate :room_not_in_maintenance
  validate :min_nights_respected

  before_validation :freeze_prices, if: -> { new_record? || price_settings_changed? }
  after_update :sync_room_state, if: :room_status_changed?

  before_destroy :free_room_state, if: :was_checked_in?

  scope :pending, -> { where(status: :pending) }
  scope :confirmed, -> { where(status: :confirmed) }
  scope :checked_in, -> { where(status: :checked_in) }
  scope :checked_out, -> { where(status: :checked_out) }
  scope :cancelled, -> { where(status: :cancelled) }
  scope :active, -> { where(status: %w[pending confirmed checked_in]) }
  scope :overlapping_period, ->(from, to) { where("check_in < ? AND check_out > ?", to, from) }

  def transition_to!(to)
    raise ArgumentError, "invalid transition #{status} -> #{to}" unless allowed_transition?(to)

    update!(status: to)
  end

  %w[pending confirmed checked_in checked_out cancelled].each do |state|
    define_method("#{state}?") { status == state }
  end

  def confirm!
    transition_to!("confirmed")
  end

  def check_in!
    transition_to!("checked_in")
  end

  def check_out!
    transition_to!("checked_out")
  end

  def cancel!
    transition_to!("cancelled")
  end

  def allowed_transition?(to)
    TRANSITIONS.fetch(status, []).include?(to.to_s)
  end

  def nights
    (check_in...check_out).to_a
  end

  def nights_count
    nights.size
  end

  def paid_amount
    payments.sum { |payment| payment["amount"].to_f }
  end

  def due_amount
    total_price.to_f - paid_amount
  end

  def add_payment!(method:, amount:, paid_at: Time.current, note: nil)
    raise ArgumentError, "invalid method" unless PAYMENT_METHODS.include?(method.to_s)
    raise ArgumentError, "amount must be positive" unless amount.to_f.positive?

    entry = {
      "id" => SecureRandom.uuid,
      "method" => method.to_s,
      "amount" => amount.to_f,
      "paid_at" => paid_at.to_time.utc.iso8601,
      "note" => note
    }
    update!(payments: payments + [ entry ])
    entry
  end

  def remove_payment!(id)
    update!(payments: payments.reject { |payment| payment["id"] == id })
  end

  def add_service!(name:, price:, quantity: 1, date: Date.current, note: nil)
    raise ArgumentError, "price must be non-negative" if price.to_f.negative?
    raise ArgumentError, "quantity must be positive" unless quantity.to_i.positive?

    entry = {
      "id" => SecureRandom.uuid,
      "name" => name,
      "price" => price.to_f,
      "quantity" => quantity.to_i,
      "date" => date.to_s,
      "note" => note,
      "status" => "confirmed"
    }
    update!(services: services + [ entry ])
    entry
  end

  def cancel_service!(id)
    update!(services: services.map do |service|
      service["id"] == id ? service.merge("status" => "cancelled") : service
    end)
  end

  def services_total
    services.select { |service| service["status"] != "cancelled" }
            .sum { |service| service["price"].to_f * service["quantity"].to_i }
  end

  def payment_received?
    paid_amount.positive?
  end

  private

  def price_settings_changed?
    persisted? && (room_id_changed? || check_in_changed? || check_out_changed?)
  end

  def freeze_prices
    return if check_in.nil? || check_out.nil? || room.nil?

    self.price_breakdown = room.nightly_breakdown(check_in, check_out).map do |entry|
      { "date" => entry[:date].to_s, "amount" => entry[:amount].round(2) }
    end
    self.total_price = price_breakdown.sum { |entry| entry["amount"] }
    self.price_frozen_on = Date.current
  end

  def dates_are_ordered
    return if check_in.nil? || check_out.nil?

    errors.add(:check_out, "должна быть позже даты заезда") unless check_out > check_in
  end

  def no_overlap
    return if room.nil? || check_in.nil? || check_out.nil?

    overlapping = room.overlapping_stays(check_in, check_out).where.not(id: id)
    errors.add(:base, "номер уже занят в выбранные даты") if overlapping.exists?
  end

  def capacity_within_room
    return if room.nil?

    errors.add(:guests_count, "превышает вместимость номера (#{room.capacity})") if guests_count.to_i > room.capacity
  end

  def room_not_in_maintenance
    return if room.nil?

    errors.add(:room, "недоступен для бронирования") if room.maintenance?
  end

  def min_nights_respected
    return if room.nil? || check_in.nil? || check_out.nil?

    nights = (check_out - check_in).to_i
    return if nights >= room.min_nights.to_i

    errors.add(:check_out, "короче минимального срока бронирования (#{room.min_nights} ноч.)")
  end

  def room_status_changed?
    return false unless saved_change_to_status?

    %w[pending confirmed cancelled].include?(status_before_last_save) && status == "checked_in" ||
      status_before_last_save == "checked_in"
  end

  def was_checked_in?
    status == "checked_in"
  end

  def sync_room_state
    room.update_columns(status: "occupied") if status == "checked_in"
    if status_before_last_save == "checked_in" && status != "checked_in"
      if room.stays.checked_in.where.not(id: id).exists?
        room.update_columns(status: "occupied")
      else
        room.update_columns(status: status == "checked_out" ? "cleaning" : "available")
      end
    end
  end

  def free_room_state
    return if room.nil?

    status = room.stays.checked_in.where.not(id: id).exists? ? "occupied" : "available"
    room.update_columns(status: status)
  end
end
