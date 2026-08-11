class Service < ApplicationRecord
  has_many :service_orders, dependent: :restrict_with_error
  has_many :reviews, as: :reviewable, dependent: :destroy
  has_many :approved_reviews, -> { approved }, as: :reviewable, class_name: "Review"

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
