class Payment < ApplicationRecord
  belongs_to :booking

  enum :method, { cash: "cash", card: "card", transfer: "transfer" }

  validates :amount, presence: { message: "не может быть пустой" },
                     numericality: { greater_than: 0, message: "должна быть больше нуля" }
  validates :paid_at, presence: true

  scope :ordered, -> { order(paid_at: :desc, id: :desc) }

  def self.method_labels
    {
      "cash" => "Наличные",
      "card" => "Карта",
      "transfer" => "Перевод"
    }
  end
end
