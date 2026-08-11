class RoomCategory < ApplicationRecord
  has_many :rooms, foreign_key: :category_id, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :base_price, numericality: { greater_than_or_equal_to: 0 }
end
