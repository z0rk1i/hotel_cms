require 'rails_helper'

RSpec.describe GalleryImage, type: :model do
  it "is valid with valid attributes" do
    expect(build(:gallery_image)).to be_valid
  end

  it "requires a title" do
    expect(build(:gallery_image, title: nil)).to be_invalid
  end

  it "requires an attached image" do
    gallery_image = build(:gallery_image)
    gallery_image.image.purge
    expect(gallery_image).to be_invalid
    expect(gallery_image.errors[:image]).to include("не выбрано")
  end
end
