require "rails_helper"

RSpec.describe "Image variants", type: :request do
  def attach_valid_image(attachment)
    attachment.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/valid_photo.jpg")),
      filename: "valid_photo.jpg",
      content_type: "image/jpeg"
    )
  end

  it "generates thumbnail variant URLs on the gallery page" do
    gallery_image = create(:gallery_image)
    attach_valid_image(gallery_image.image)

    get gallery_path

    expect(response.body).to include("representations")
    expect(response.body).to include(gallery_image.image.blob.signed_id)
  end

  it "serves a processed thumbnail variant" do
    gallery_image = create(:gallery_image)
    attach_valid_image(gallery_image.image)
    variant = ApplicationController.helpers.image_thumb(gallery_image.image, size: [ 320, 160 ])

    get rails_representation_path(variant)
    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eq("image/jpeg")
  end

  it "uses thumbnail variants for room photos on the room page" do
    room = create(:room)
    attach_valid_image(room.photos)
    attach_valid_image(room.photos)

    get room_path(room)

    expect(response.body).to include("representations")
  end
end
