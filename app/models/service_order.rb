class ServiceOrder < ApplicationRecord
  belongs_to :service
  belongs_to :user

  enum :status, { pending: "pending", confirmed: "confirmed", cancelled: "cancelled" }

  validates :service_date, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  before_save :calculate_total_price

  scope :ordered, -> { order(service_date: :desc, created_at: :desc) }

  after_update :notify_status_change, if: -> { saved_change_to_status? }

  private

  def notify_status_change
    user.notifications.create!(
      notifiable: self,
      kind: "service_order_status",
      title: "Статус заказа услуги изменён",
      body: "Заказ «#{service.name}» на #{I18n.l(service_date, format: :long)} — #{self.class.status_labels.fetch(status.to_s, status)}."
    )
  end

  def self.status_labels
    {
      "pending" => "ожидает подтверждения",
      "confirmed" => "подтверждён",
      "cancelled" => "отменён"
    }
  end

  def calculate_total_price
    self.total_price = service.price.present? ? service.price * quantity : 0
  end
end
