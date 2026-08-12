class Review < ApplicationRecord
  belongs_to :reviewable, polymorphic: true
  belongs_to :user

  enum :status, { pending: "pending", approved: "approved", rejected: "rejected" }

  REVIEWABLE_TYPES = %w[Room Service].freeze

  validates :rating, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :body, presence: true, length: { maximum: 5000 }
  validate :reviewable_type_allowed

  scope :approved, -> { where(status: :approved) }
  scope :ordered, -> { order(created_at: :desc) }

  RATING_LABELS = {
    1 => "1 — ужасно",
    2 => "2 — плохо",
    3 => "3 — нормально",
    4 => "4 — хорошо",
    5 => "5 — отлично"
  }.freeze

  def self.status_labels
    {
      "pending" => "на модерации",
      "approved" => "одобрен",
      "rejected" => "отклонён"
    }
  end

  private

  def reviewable_type_allowed
    return if reviewable_type.in?(REVIEWABLE_TYPES) && reviewable.present?

    errors.add(:reviewable_type, "не является допустимым объектом отзыва")
  end
end
