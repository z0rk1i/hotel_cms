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
end
