class Room < ApplicationRecord
  belongs_to :category, class_name: "RoomCategory"

  has_many :bookings, dependent: :restrict_with_error
  has_many :reviews, as: :reviewable, dependent: :destroy
  has_many :approved_reviews, -> { approved }, as: :reviewable, class_name: "Review"
  has_many_attached :photos
  has_many :room_amenities, dependent: :destroy
  has_many :amenities, through: :room_amenities
  has_many :status_logs, class_name: "RoomStatusLog", dependent: :destroy

  enum :status, { available: "available", occupied: "occupied", maintenance: "maintenance", cleaning: "cleaning" }

  after_update :log_status_change, if: -> { saved_change_to_status? }

  validates :number, presence: true, uniqueness: true
  validates :floor, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :capacity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :price_per_night, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :weekend_multiplier, numericality: { greater_than: 0 }, allow_nil: true
  validates :size_sqm, numericality: { greater_than: 0 }, allow_nil: true

  validate :photo_count_within_limit
  validate :photo_size_within_limit
  validate :no_maintenance_while_guests_inside, on: :update, if: -> { status_changed? && (maintenance? || cleaning?) }
  validate :unavailability_window_valid

  scope :available_now, -> { where(status: :available) }
  scope :in_unavailability_window, ->(start_date, end_date) do
    where("unavailable_from IS NOT NULL AND unavailable_until IS NOT NULL " \
          "AND unavailable_from < ? AND unavailable_until > ?", end_date, start_date)
  end
  scope :bookable_on, ->(start_date, end_date) do
    where.not(id: in_unavailability_window(start_date, end_date).select(:id))
  end
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

  def unavailable_during?(start_date, end_date)
    unavailable_from.present? && unavailable_until.present? &&
      unavailable_from < end_date && unavailable_until > start_date
  end

  private

  def log_status_change
    from, to = saved_change_to_status
    RoomStatusLog.record!(room: self, from: from, to: to)
  end

  def unavailability_window_valid
    return if unavailable_from.blank? || unavailable_until.blank?

    errors.add(:unavailable_until, "должна быть позже даты начала") if unavailable_until <= unavailable_from
  end

  def no_maintenance_while_guests_inside
    return unless bookings.occupying_overlapping(Date.current, Date.current + 1).exists?

    errors.add(:status, "нельзя перевести в ремонт/уборку, пока в номере гости")
  end

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
