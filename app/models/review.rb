class Review < ApplicationRecord
  include ConstraintGuarded

  belongs_to :reviewable, polymorphic: true
  belongs_to :user

  after_commit :notify_admins_of_new_review, on: :create

  enum :status, { pending: "pending", approved: "approved", rejected: "rejected" }

  REVIEWABLE_TYPES = %w[Room Service].freeze

  guard_constraint_error :reviewable, "вы уже оставляли отзыв об этом объекте"

  validates :rating, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :body, presence: true, length: { maximum: 5000 }
  validate :reviewable_type_allowed
  validate :one_review_per_user
  validate :reviewable_stayed

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

  def one_review_per_user
    return if user_id.blank? || reviewable_type.blank? || reviewable_id.blank?

    duplicate = self.class.where(user_id: user_id, reviewable_type: reviewable_type, reviewable_id: reviewable_id)
                          .where.not(id: id)
    errors.add(:reviewable, "вы уже оставляли отзыв об этом объекте") if duplicate.exists?
  end

  def reviewable_stayed
    return if user.blank? || reviewable.blank?
    return if stayed_for_reviewable?

    errors.add(:base, "оставить отзыв можно только после проживания или заказа услуги")
  end

  def stayed_for_reviewable?
    case reviewable_type
    when "Room"
      user.bookings.where(room_id: reviewable_id, status: %i[checked_in checked_out]).exists?
    when "Service"
      user.service_orders.where(service_id: reviewable_id, status: :confirmed).exists?
    else
      false
    end
  end

  def notify_admins_of_new_review
    AdminMailer.new_review(self).deliver_later if Administrator.exists?
  end
end
