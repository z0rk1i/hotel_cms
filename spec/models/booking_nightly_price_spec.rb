require "rails_helper"

RSpec.describe BookingNightlyPrice, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:booking_nightly_price)).to be_valid
    end

    it "requires a date" do
      expect(build(:booking_nightly_price, date: nil)).to be_invalid
    end

    it "requires a non-negative amount" do
      expect(build(:booking_nightly_price, amount: -1)).to be_invalid
    end

    it "rejects duplicate dates for the same booking" do
      booking = create(:booking)
      create(:booking_nightly_price, booking: booking, date: Date.current + 1)
      duplicate = build(:booking_nightly_price, booking: booking, date: Date.current + 1)
      expect(duplicate).to be_invalid
    end
  end
end
