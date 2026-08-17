class StaticContent
  require "pathname"
  PAGES_PATH = Pathname.new(File.join(APP_ROOT, "db", "seeds", "static"))

  def self.all_pages
    @all_pages ||= YAML.safe_load_file(PAGES_PATH.join("pages.yml"), permitted_classes: [ Date ]).freeze
  end

  def self.page(slug)
    all_pages[slug.to_s]
  end

  def self.all_news
    @all_news ||= YAML.safe_load_file(PAGES_PATH.join("news.yml"), permitted_classes: [ Date ]).sort_by { |item| item["date"] }.reverse.freeze
  end

  def self.news(slug = nil)
    return all_news if slug.nil?

    all_news.find { |item| item["slug"] == slug.to_s }
  end
end
