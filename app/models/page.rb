class Page < ApplicationRecord
  include Sluggable

  validates :title, presence: true
end
