require 'rails_helper'

RSpec.describe Room, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:room)).to be_valid
    end

    it "requires a unique number" do
      create(:room, number: "101")
      expect(build(:room, number: "101")).to be_invalid
      expect(build(:room, number: "102")).to be_valid
    end

    it "requires a positive capacity" do
      expect(build(:room, capacity: 0)).to be_invalid
    end

    it "requires non-negative price" do
      expect(build(:room, price_per_night: -1)).to be_invalid
    end
  end

  describe "#label" do
    it "combines number and category name" do
      room = build(:room, number: "101")
      expect(room.label).to eq("101 — #{room.category.name}")
    end
  end

  describe "#occupied_during?" do
    let!(:room) { create(:room) }

    it "is false without bookings" do
      expect(room.occupied_during?(Date.current, Date.current + 2)).to be(false)
    end

    it "is true when an active booking overlaps" do
      create(:booking, room: room, check_in: Date.current + 1, check_out: Date.current + 3)
      expect(room.occupied_during?(Date.current + 2, Date.current + 4)).to be(true)
    end

    it "is false when booking is cancelled" do
      create(:booking, :cancelled, room: room, check_in: Date.current + 1, check_out: Date.current + 3)
      expect(room.occupied_during?(Date.current + 2, Date.current + 4)).to be(false)
    end

    it "excludes the booking being edited" do
      booking = create(:booking, room: room, check_in: Date.current + 1, check_out: Date.current + 3)
      expect(room.occupied_during?(Date.current + 1, Date.current + 3, exclude_booking: booking)).to be(false)
    end
  end

  describe "status enum" do
    it "defines the expected statuses" do
      expect(Room.statuses.keys).to include("available", "occupied", "maintenance", "cleaning")
    end

    it "scopes available rooms" do
      create(:room, status: :available)
      create(:room, status: :occupied)
      expect(Room.available_now.count).to eq(1)
    end
  end
end
