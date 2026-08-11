class Review < ApplicationRecord
  belongs_to :reviewable, polymorphic: true
  belongs_to :user

  enum :status, { pending: "pending", approved: "approved", rejected: "rejected" }

  validates :rating, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :body, presence: true, length: { maximum: 5000 }

  scope :approved, -> { where(status: :approved) }
  scope :ordered, -> { order(created_at: :desc) }

  RATING_LABELS = {
    1 => "1 — ужасно",
    2 => "2 — плохо",
    3 => "3 — нормально",
    4 => "4 — хорошо",
    5 => "5 — отлично"
  }.freeze
end
