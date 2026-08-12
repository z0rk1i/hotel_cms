require "rails_helper"

RSpec.describe "Admin gallery images", type: :request do
  before { sign_in create(:administrator) }

  let(:pixel_file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/pixel.png"), "image/png") }

  it_behaves_like "admin CRUD resource" do
    let(:model_class) { GalleryImage }
    let(:collection_path) { admin_gallery_images_path }
    let(:new_form_path) { new_admin_gallery_image_path }
    let(:initial_title) { "Вид на озеро" }
    let(:record) { create(:gallery_image, title: initial_title) }
    let(:edit_member_path) { edit_admin_gallery_image_path(record) }
    let(:member_path) { admin_gallery_image_path(record) }
    let(:listed_title) { initial_title }
    let(:valid_attrs) { { title: "Вид на озеро", image: pixel_file } }
    let(:invalid_attrs) { { title: "" } }
    let(:update_attrs) { { title: "Новое название" } }
  end

  describe "PATCH /admin/gallery_images/:id" do
    it "replaces the image when a new one is uploaded" do
      image = create(:gallery_image)
      old_blob = image.image.blob
      patch admin_gallery_image_path(image), params: {
        gallery_image: { title: image.title, image: pixel_file }
      }
      expect(image.reload.image).to be_attached
      expect(image.image.blob).not_to eq(old_blob)
    end

    it "keeps the image when no new one is uploaded" do
      image = create(:gallery_image)
      blob = image.image.blob
      patch admin_gallery_image_path(image), params: { gallery_image: { title: "Новый заголовок" } }
      expect(image.reload.image.blob).to eq(blob)
      expect(response).to redirect_to(admin_gallery_images_path)
    end
  end

  describe "redirects after successful changes" do
    it "redirects to the previous page after updating" do
      image = create(:gallery_image)
      get edit_admin_gallery_image_path(image), headers: { "HTTP_REFERER" => admin_gallery_images_path }
      patch admin_gallery_image_path(image), params: { gallery_image: { title: "Обновлённое название" } }
      expect(response).to redirect_to(admin_gallery_images_path)
    end
  end
end
