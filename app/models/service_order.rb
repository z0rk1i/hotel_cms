class ServiceOrder < ApplicationRecord
  include StatusNotifiable
  include StatusTransitionable

  belongs_to :service
  belongs_to :user
  belongs_to :booking

  enum :status, { pending: "pending", confirmed: "confirmed", cancelled: "cancelled" }

  transitions_for(
    pending: %i[confirmed cancelled],
    confirmed: %i[cancelled],
    cancelled: []
  )

  validates :service_date, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validate :service_date_not_in_past
  validate :booking_active_and_covers_date, on: :create

  before_save :calculate_total_price

  scope :ordered, -> { order(service_date: :desc, created_at: :desc) }

  def self.status_labels
    {
      "pending" => "ожидает подтверждения",
      "confirmed" => "подтверждён",
      "cancelled" => "отменён"
    }
  end

  private

  def service_date_not_in_past
    return if service_date.blank?

    errors.add(:service_date, "не может быть в прошлом") if service_date < Date.current
  end

  def booking_active_and_covers_date
    return if booking.blank?
    return errors.add(:booking, "не принадлежит пользователю") if booking.user_id != user_id

    unless %w[confirmed checked_in].include?(booking.status)
      return errors.add(:booking, "не активна — услуги доступны при подтверждённой брони")
    end

    if service_date.present? && (service_date < booking.check_in || service_date >= booking.check_out)
      errors.add(:service_date, "должна попадать в период брони")
    end
  end

  def calculate_total_price
    self.total_price = service.price.present? ? service.price * quantity : 0
  end

  def notification_kind
    "service_order_status"
  end

  def notification_title
    "Статус заказа услуги изменён"
  end

  def notification_body
    "Заказ «#{service.name}» на #{I18n.l(service_date, format: :long)} — #{self.class.status_labels.fetch(status.to_s, status)}."
  end
end
