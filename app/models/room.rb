class Room < ApplicationRecord
  belongs_to :category, class_name: "RoomCategory"

  has_many :bookings, dependent: :restrict_with_error
  has_many_attached :photos

  enum :status, { available: "available", occupied: "occupied", maintenance: "maintenance", cleaning: "cleaning" }

  validates :number, presence: true, uniqueness: true
  validates :floor, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :capacity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :price_per_night, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :size_sqm, numericality: { greater_than: 0 }, allow_nil: true

  scope :available_now, -> { where(status: :available) }

  def label
    "#{number} — #{category.name}"
  end

  def occupied_during?(start_date, end_date, exclude_booking: nil)
    bookings.active_overlapping(start_date, end_date).where.not(id: exclude_booking&.id).exists?
  end
end
