class Amenity < ApplicationRecord
  has_many :room_amenities, dependent: :destroy
  has_many :rooms, through: :room_amenities

  validates :name, presence: true, uniqueness: true
  validates :icon, presence: true

  def label
    "#{name}#{icon.present? ? " (#{icon})" : ""}"
  end
end
