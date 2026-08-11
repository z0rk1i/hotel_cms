class News < ApplicationRecord
  include Sluggable

  validates :title, presence: true

  scope :published, -> { where("published_at <= ?", Time.current).order(published_at: :desc) }
end
