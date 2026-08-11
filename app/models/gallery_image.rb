class GalleryImage < ApplicationRecord
  has_one_attached :image

  validates :title, presence: true
  validate :image_attached

  private

  def image_attached
    errors.add(:image, "не выбрано") unless image.attached?
  end
end
