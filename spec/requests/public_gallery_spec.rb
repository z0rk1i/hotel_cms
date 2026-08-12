require "rails_helper"

RSpec.describe "Public gallery", type: :request do
  describe "GET /gallery" do
    it "renders all gallery images without authentication" do
      first = create(:gallery_image, title: "Вид на озеро")
      second = create(:gallery_image, title: "Ресторан")

      get gallery_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Галерея")
      expect(response.body).to include(first.title)
      expect(response.body).to include(second.title)
      expect(response.body).to include("1 / 2")
    end

    it "shows an empty state when there are no images" do
      get gallery_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Фотографии появятся скоро")
    end
  end

  describe "homepage gallery section" do
    it "renders preview images and a link to the full gallery" do
      image = create(:gallery_image, title: "Вид на озеро")
      get root_path
      expect(response.body).to include("Смотреть все")
      expect(response.body).to include(image.title)
      expect(response.body).to include(gallery_path)
    end
  end
end
