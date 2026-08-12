require "rails_helper"

RSpec.describe "Admin gallery images", type: :request do
  before { sign_in create(:administrator) }

  let(:pixel_file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/pixel.png"), "image/png") }

  describe "GET /admin/gallery_images" do
    it "lists gallery images" do
      image = create(:gallery_image, title: "Вид на озеро")
      get admin_gallery_images_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Вид на озеро")
      expect(response.body).to include(image.title)
    end
  end

  describe "GET /admin/gallery_images/new" do
    it "renders the form" do
      get new_admin_gallery_image_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Добавить фото в галерею")
    end
  end

  describe "POST /admin/gallery_images" do
    it "creates a gallery image" do
      expect do
        post admin_gallery_images_path, params: {
          gallery_image: { title: "Вид на озеро", image: pixel_file }
        }
      end.to change(GalleryImage, :count).by(1)

      expect(GalleryImage.last.title).to eq("Вид на озеро")
      expect(GalleryImage.last.image).to be_attached
      expect(response).to redirect_to(admin_gallery_images_path)
    end

    it "re-renders the form on invalid attributes" do
      post admin_gallery_images_path, params: { gallery_image: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/gallery_images/:id/edit" do
    it "renders the edit form with the current title" do
      image = create(:gallery_image, title: "Вид на озеро")
      get edit_admin_gallery_image_path(image)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Редактировать фото галереи")
      expect(response.body).to include("Вид на озеро")
    end
  end

  describe "PATCH /admin/gallery_images/:id" do
    it "updates the title" do
      image = create(:gallery_image, title: "Старое название")
      patch admin_gallery_image_path(image), params: { gallery_image: { title: "Новое название" } }
      expect(image.reload.title).to eq("Новое название")
      expect(response).to redirect_to(admin_gallery_images_path)
    end

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

    it "re-renders the form on invalid attributes" do
      image = create(:gallery_image)
      patch admin_gallery_image_path(image), params: { gallery_image: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(image.reload.title).not_to be_blank
    end
  end

  describe "DELETE /admin/gallery_images/:id" do
    it "destroys the gallery image" do
      image = create(:gallery_image)
      expect do
        delete admin_gallery_image_path(image)
      end.to change(GalleryImage, :count).by(-1)
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
