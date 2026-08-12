class BookingNightlyPrice < ApplicationRecord
  belongs_to :booking

  validates :date, presence: true, uniqueness: { scope: :booking_id }
  validates :amount, presence: true,
                     numericality: { greater_than_or_equal_to: 0, message: "не может быть отрицательной" }

  scope :ordered, -> { order(:date) }
end
