class RatelimitCounter < ApplicationRecord
  validates :name, presence: true
  validates :classification, presence: true
  validates :epoch, presence: true
  validates :count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
