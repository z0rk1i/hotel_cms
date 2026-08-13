require "rails_helper"

RSpec.describe "Public news", type: :request do
  describe "GET /news" do
    it "lists news entries from static content" do
      get news_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Новости")
    end
  end

  describe "GET /news/:slug" do
    it "renders a news article" do
      get news_article_path("spa-center")
      expect(response).to have_http_status(:ok)
    end

    it "404s for an unknown slug" do
      get news_article_path("nope")
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /page/:slug" do
    it "renders a static page" do
      get page_path("contacts")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Контакты")
    end

    it "404s for an unknown slug" do
      get page_path("nope")
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /privacy" do
    it "renders the privacy policy" do
      get privacy_policy_path
      expect(response).to have_http_status(:ok)
    end
  end
end
