require "rails_helper"

RSpec.describe "Public gallery", type: :request do
  describe "GET /gallery" do
    it "renders the gallery page" do
      create(:room, category: "Люкс", number: "201")

      get gallery_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Галерея")
    end

    it "shows rooms with photos" do
      create(:room, :with_photos, category: "Стандарт", number: "301")

      get gallery_path

      expect(response.body).to include("301")
    end
  end
end
