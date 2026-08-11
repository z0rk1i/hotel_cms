class News < ApplicationRecord
  validates :title, presence: true

  scope :published, -> { where("published_at <= ?", Time.current).order(published_at: :desc) }
end
