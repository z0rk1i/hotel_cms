require 'rails_helper'

RSpec.describe Guest, type: :model do
  it "is valid with valid attributes" do
    expect(build(:guest)).to be_valid
  end

  it "requires a full name" do
    expect(build(:guest, full_name: nil)).to be_invalid
  end

  it "rejects malformed emails" do
    expect(build(:guest, email: "not-an-email")).to be_invalid
  end

  it "allows blank email" do
    expect(build(:guest, email: nil)).to be_valid
  end

  describe ".search" do
    it "finds guests by name substring" do
      guest = create(:guest, full_name: "Анна Смирнова")
      expect(Guest.search("смирн")).to include(guest)
    end

    it "finds guests by phone substring" do
      guest = create(:guest, phone: "+7 900 123-45-67")
      expect(Guest.search("123-45")).to include(guest)
    end

    it "returns all when query is blank" do
      expect(Guest.search("")).to eq(Guest.all)
    end
  end
end
