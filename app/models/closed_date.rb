class ClosedDate < ApplicationRecord
  validates :date, presence: true, uniqueness: true
  validates :reason, length: { maximum: 200 }

  scope :ordered, -> { order(:date) }
  scope :upcoming, -> { where(date: Date.current..).order(:date) }
end
