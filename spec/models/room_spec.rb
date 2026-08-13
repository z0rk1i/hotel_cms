require "rails_helper"

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

    it "requires a category" do
      expect(build(:room, category: nil)).to be_invalid
    end

    it "requires a positive capacity" do
      expect(build(:room, capacity: 0)).to be_invalid
    end

    it "requires non-negative price" do
      expect(build(:room, price_per_night: -1)).to be_invalid
    end

    it "requires min_nights >= 1" do
      expect(build(:room, min_nights: 0)).to be_invalid
    end

    it "rejects unknown status" do
      expect(build(:room, status: "booked")).to be_invalid
    end
  end

  describe "#price_for_night" do
    it "applies the weekend multiplier on Friday and Saturday" do
      room = create(:room, price_per_night: 1000, weekend_multiplier: 1.5)

      monday = Date.new(2026, 8, 10)
      saturday = Date.new(2026, 8, 15)

      expect(room.price_for_night(monday)).to eq(1000)
      expect(room.price_for_night(saturday)).to eq(1500)
    end
  end

  describe "#price_for_stay" do
    it "sums nightly prices over the stay" do
      room = create(:room, price_per_night: 1000, weekend_multiplier: 1.0)

      expect(room.price_for_stay(Date.new(2026, 8, 10), Date.new(2026, 8, 13))).to eq(3000)
    end
  end

  describe "#available?" do
    it "is true only when status is available" do
      expect(build(:room)).to be_available
      expect(build(:room, :maintenance)).not_to be_available
      expect(build(:room, :cleaning)).not_to be_available
    end
  end

  describe "#bookable?" do
    it "blocks only maintenance" do
      expect(build(:room)).to be_bookable
      expect(build(:room, :cleaning)).to be_bookable
      expect(build(:room, :maintenance)).not_to be_bookable
    end
  end

  describe "#available_on?" do
    it "returns true when no overlapping stays" do
      room = create(:room)
      expect(room.available_on?(Date.current + 1, Date.current + 3)).to be(true)
    end

    it "returns false when a stay overlaps" do
      room = create(:room)
      create(:stay, :confirmed, room: room, check_in: Date.current + 1, check_out: Date.current + 3)
      expect(room.available_on?(Date.current, Date.current + 2)).to be(false)
    end

    it "returns false when the room is in maintenance" do
      room = create(:room, :maintenance)
      expect(room.available_on?(Date.current + 1, Date.current + 3)).to be(false)
    end

    it "returns false during an unavailable window" do
      room = create(:room, :unavailable)
      expect(room.available_on?(Date.current, Date.current + 1)).to be(false)
    end
  end

  describe "#occupied_now?" do
    it "is true when a checked_in stay overlaps today" do
      room = create(:room)
      create(:stay, :checked_in, room: room)
      expect(room.occupied_now?).to be(true)
    end

    it "is false for confirmed stays" do
      room = create(:room)
      create(:stay, :confirmed, room: room)
      expect(room.occupied_now?).to be(false)
    end
  end

  describe "#next_free_window" do
    it "returns the first window of min_nights length" do
      room = create(:room, min_nights: 2, price_per_night: 1000, weekend_multiplier: 1.0)

      result = room.next_free_window

      expect(result[:check_in]).to eq(Date.current)
      expect(result[:check_out]).to eq(Date.current + 2)
      expect(result[:price]).to eq(2000)
    end
  end

  describe "reviews" do
    it "returns only approved reviews" do
      room = create(:room, reviews: [
        { "status" => "approved", "rating" => 5, "body" => "ok", "author" => "A", "created_at" => Time.current.iso8601 },
        { "status" => "pending", "rating" => 1, "body" => "wait", "author" => "B", "created_at" => Time.current.iso8601 }
      ])

      expect(room.approved_reviews.size).to eq(1)
      expect(room.review_average).to eq(5.0)
    end

    it "add_review appends a pending review" do
      room = create(:room)
      user = create(:user, full_name: "Иван Петров")

      entry = room.add_review(user: user, rating: 4, body: "Хорошо")

      expect(entry["status"]).to eq("pending")
      expect(room.reviews.last["author"]).to eq("Иван Петров")
    end
  end
end
