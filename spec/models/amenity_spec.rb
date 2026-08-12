require "rails_helper"

RSpec.describe Amenity, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:amenity)).to be_valid
    end

    it "requires a name" do
      expect(build(:amenity, name: nil)).to be_invalid
    end

    it "requires a unique name" do
      create(:amenity, name: "Wi-Fi")
      expect(build(:amenity, name: "Wi-Fi")).to be_invalid
    end

    it "requires an icon" do
      expect(build(:amenity, icon: nil)).to be_invalid
    end
  end

  describe "associations" do
    it "returns rooms through room_amenities" do
      room = create(:room)
      amenity = create(:amenity)
      room.amenities << amenity
      expect(amenity.reload.rooms).to include(room)
    end

    it "destroys room_amenities links when the amenity is destroyed" do
      amenity = create(:amenity)
      room = create(:room)
      room.amenities << amenity
      expect { amenity.destroy }.to change(RoomAmenity, :count).by(-1)
    end
  end

  describe "#label" do
    it "combines name and icon" do
      expect(Amenity.new(name: "Wi-Fi", icon: "wifi").label).to eq("Wi-Fi (wifi)")
    end
  end
end
