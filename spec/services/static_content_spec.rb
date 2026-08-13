require "rails_helper"

RSpec.describe StaticContent, type: :service do
  describe ".all_pages" do
    it "loads pages from the YAML file" do
      pages = described_class.all_pages
      expect(pages).to have_key("about")
      expect(pages["contacts"]["title"]).to eq("Контакты")
    end
  end

  describe ".page" do
    it "returns a page by slug" do
      page = described_class.page("contacts")
      expect(page["title"]).to eq("Контакты")
    end

    it "returns nil for unknown slugs" do
      expect(described_class.page("nope")).to be_nil
    end
  end

  describe ".all_news" do
    it "loads news sorted by date descending" do
      news = described_class.all_news
      expect(news.map { |item| item["slug"] }).to eq(%w[spa-center weekend-offer])
    end
  end

  describe ".news" do
    it "returns all news when no slug" do
      expect(described_class.news).to eq(described_class.all_news)
    end

    it "finds a single article by slug" do
      article = described_class.news("spa-center")
      expect(article["title"]).to eq("Открытие нового спа-центра")
    end
  end
end
