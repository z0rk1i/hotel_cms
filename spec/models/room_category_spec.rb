require 'rails_helper'

RSpec.describe RoomCategory, type: :model do
  it "is valid with valid attributes" do
    expect(build(:room_category)).to be_valid
  end

  it "requires a name" do
    expect(build(:room_category, name: nil)).to be_invalid
  end

  it "requires a unique name" do
    create(:room_category, name: "Люкс")
    expect(build(:room_category, name: "Люкс")).to be_invalid
  end

  it "rejects negative base price" do
    expect(build(:room_category, base_price: -5)).to be_invalid
  end

  it "prevents deletion when rooms exist" do
    category = create(:room_category)
    create(:room, category: category)
    expect { category.destroy }.not_to change(RoomCategory, :count)
  end
end
