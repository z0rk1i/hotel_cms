require 'rails_helper'

RSpec.describe News, type: :model do
  it "is valid with valid attributes" do
    expect(build(:news)).to be_valid
  end

  it "requires a title" do
    expect(build(:news, title: nil)).to be_invalid
  end

  describe ".published" do
    it "includes news published now or in the past" do
      past = create(:news, published_at: 1.day.ago)
      expect(News.published).to include(past)
    end

    it "excludes future news" do
      future = create(:news, published_at: 1.day.from_now)
      expect(News.published).not_to include(future)
    end
  end

  describe "slug" do
    it "generates a unique slug from the title" do
      news = create(:news, title: "Открытие нового СПА")
      expect(news.reload.slug).to eq("otkrytie-novogo-spa")
    end

    it "guarantees uniqueness by appending a suffix" do
      create(:news, title: "Скидки на выходные")
      second = create(:news, title: "Скидки на выходные")
      expect(second.slug).to start_with("skidki-na-vykhodnye")
      expect(News.pluck(:slug).uniq.size).to eq(2)
    end

    it "is required" do
      news = build(:news, title: nil)
      expect(news).to be_invalid
    end
  end
end
