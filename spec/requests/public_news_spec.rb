require "rails_helper"

RSpec.describe "Public news", type: :request do
  describe "GET /news/:slug" do
    it "renders a published news article by slug" do
      news = create(:news, title: "Спецпредложение на выходные")
      get "/news/#{news.slug}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(news.title)
    end

    it "returns 404 for an unknown slug" do
      get "/news/nonexistent"
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for future news" do
      news = create(:news, published_at: 1.day.from_now)
      get "/news/#{news.slug}"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "homepage" do
    it "links published news cards to their article pages" do
      news = create(:news, title: "Открытие бассейна")
      get root_path
      expect(response.body).to include("/news/#{news.slug}")
      expect(response.body).to include("Читать далее")
    end
  end
end
