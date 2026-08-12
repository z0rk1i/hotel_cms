class ServiceOrder < ApplicationRecord
  include StatusNotifiable
  include StatusTransitionable

  belongs_to :service
  belongs_to :user

  enum :status, { pending: "pending", confirmed: "confirmed", cancelled: "cancelled" }

  transitions_for(
    pending: %i[confirmed cancelled],
    confirmed: %i[cancelled],
    cancelled: []
  )

  validates :service_date, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validate :service_date_not_in_past

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
