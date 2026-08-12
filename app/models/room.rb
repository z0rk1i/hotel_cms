class Room < ApplicationRecord
  belongs_to :category, class_name: "RoomCategory"

  has_many :bookings, dependent: :restrict_with_error
  has_many :reviews, as: :reviewable, dependent: :destroy
  has_many :approved_reviews, -> { approved }, as: :reviewable, class_name: "Review"
  has_many_attached :photos
  has_many :room_amenities, dependent: :destroy
  has_many :amenities, through: :room_amenities

  enum :status, { available: "available", occupied: "occupied", maintenance: "maintenance", cleaning: "cleaning" }

  validates :number, presence: true, uniqueness: true
  validates :floor, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :capacity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :price_per_night, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :size_sqm, numericality: { greater_than: 0 }, allow_nil: true

  validate :photo_count_within_limit
  validate :photo_size_within_limit

  scope :available_now, -> { where(status: :available) }
  scope :with_all_amenities, ->(ids) do
    ids = Array(ids).map(&:to_i).reject(&:zero?)
    next all if ids.empty?

    joins(:room_amenities)
      .where(room_amenities: { amenity_id: ids })
      .group("rooms.id")
      .having("COUNT(DISTINCT room_amenities.amenity_id) = ?", ids.size)
  end

  MAX_PHOTOS = 10
  MAX_PHOTO_SIZE = 10.megabytes

  def label
    "#{number} — #{category.name}"
  end

  def occupied_during?(start_date, end_date, exclude_booking: nil)
    bookings.active_overlapping(start_date, end_date).where.not(id: exclude_booking&.id).exists?
  end

  private

  def photo_count_within_limit
    return if photos.count <= MAX_PHOTOS

    errors.add(:photos, "не более #{MAX_PHOTOS} фотографий на номер")
  end

  def photo_size_within_limit
    photos.each do |photo|
      next unless photo.blob&.byte_size.to_i > MAX_PHOTO_SIZE

      errors.add(:photos, "фотография #{photo.filename} больше 10 МБ")
    end
  end
end
