require 'rails_helper'

RSpec.describe Booking, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:booking)).to be_valid
    end

    it "requires check_in and check_out" do
      booking = build(:booking, check_in: nil, check_out: nil)
      expect(booking).to be_invalid
      expect(booking.errors[:check_in]).to be_present
      expect(booking.errors[:check_out]).to be_present
    end

    it "rejects check_out before check_in" do
      booking = build(:booking, check_in: Date.current, check_out: Date.current)
      expect(booking).to be_invalid
      expect(booking.errors[:check_out]).to include("должна быть позже даты заезда")
    end

    it "rejects guests count above room capacity" do
      booking = build(:booking, guests_count: 99)
      expect(booking).to be_invalid
      expect(booking.errors[:guests_count]).to include("превышает вместимость номера")
    end
  end

  describe "date overlap" do
    let!(:booking) { create(:booking, check_in: Date.current + 3, check_out: Date.current + 5) }

    it "rejects an overlapping booking for the same room" do
      overlap = build(:booking, room: booking.room, check_in: Date.current + 4, check_out: Date.current + 6)
      expect(overlap).to be_invalid
      expect(overlap.errors[:room]).to include("уже забронирован на выбранные даты")
    end

    it "rejects a booking fully contained in an existing one" do
      overlap = build(:booking, room: booking.room, check_in: Date.current + 3, check_out: Date.current + 5)
      expect(overlap).to be_invalid
    end

    it "allows adjacent bookings (check_out == next check_in)" do
      adjacent = build(:booking, room: booking.room, check_in: booking.check_out, check_out: booking.check_out + 2)
      expect(adjacent).to be_valid
    end

    it "allows a booking for a different room on the same dates" do
      other_room = create(:room)
      other = build(:booking, room: other_room, check_in: booking.check_in, check_out: booking.check_out)
      expect(other).to be_valid
    end

    it "ignores cancelled bookings when checking overlap" do
      cancelled = create(:booking, :cancelled, room: booking.room,
                                        check_in: booking.check_in, check_out: booking.check_out)
      expect(cancelled).to be_valid
      expect(booking.room.occupied_during?(booking.check_in, booking.check_out, exclude_booking: booking)).to be(false)
    end

    it "excludes itself when validating an update" do
      booking.update!(check_out: booking.check_out + 1)
      expect(booking).to be_valid
    end
  end

  describe "price calculation" do
    it "computes total price from nights and room rate" do
      room = create(:room, price_per_night: 1000)
      booking = create(:booking, room: room, check_in: Date.current + 1, check_out: Date.current + 4)
      expect(booking.nights).to eq(3)
      expect(booking.total_price).to eq(3000)
    end

    it "recalculates price when dates change" do
      room = create(:room, price_per_night: 1000)
      booking = create(:booking, room: room, check_in: Date.current + 1, check_out: Date.current + 2)
      booking.update!(check_out: Date.current + 5)
      expect(booking.total_price).to eq(4000)
    end
  end

  describe "scopes" do
    it "excludes cancelled from active" do
      create(:booking)
      create(:booking, :cancelled)
      expect(Booking.active.count).to eq(1)
    end

    it "finds active_overlapping ranges" do
      create(:booking, check_in: Date.current + 3, check_out: Date.current + 5)
      expect(Booking.active_overlapping(Date.current + 4, Date.current + 6).count).to eq(1)
      expect(Booking.active_overlapping(Date.current + 6, Date.current + 8).count).to eq(0)
    end
  end
end
