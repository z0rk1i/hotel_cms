class ConsentLog < ApplicationRecord
  belongs_to :guest

  validates :signed_at, presence: true

  scope :ordered, -> { order(signed_at: :desc) }
end
