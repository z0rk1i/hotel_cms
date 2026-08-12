require "rails_helper"

RSpec.describe RoomAvailability do
  describe "#call" do
    it "returns Success with available rooms as hashes, ordered by floor then number" do
      category = create(:room_category, name: "Стандарт")
      create(:room, number: "B", floor: 2, category: category)
      create(:room, number: "A", floor: 1, category: category)
      create(:room, number: "C", floor: 1, category: category)

      result = described_class.new.call(check_in: Date.current + 3, check_out: Date.current + 5)

      expect(result).to be_success
      expect(result.value!.map { |r| r[:label] }).to eq([ "A — Стандарт", "C — Стандарт", "B — Стандарт" ])
    end

    it "returns numeric price and a total_price computed by NightlyPricing" do
      room = create(:room, price_per_night: 1000)
      check_in = Date.current + 3
      check_out = Date.current + 5
      expect(NightlyPricing).to receive(:new)
        .with(room: room, check_in: check_in, check_out: check_out)
        .and_call_original

      result = described_class.new.call(check_in: check_in, check_out: check_out)

      entry = result.value!.first
      expect(entry[:id]).to eq(room.id)
      expect(entry[:price]).to eq(1000.0)
      expect(entry[:total_price]).to eq(2000.0)
      expect(entry[:capacity]).to eq(room.capacity)
    end

    it "excludes rooms with an active overlapping booking" do
      taken = create(:room)
      create(:booking, room: taken, check_in: Date.current + 3, check_out: Date.current + 5)
      free = create(:room)

      result = described_class.new.call(check_in: Date.current + 3, check_out: Date.current + 5)

      expect(result.value!.map { |r| r[:id] }).to eq([ free.id ])
    end

    it "ignores cancelled bookings" do
      cancelled = create(:room)
      create(:booking, room: cancelled, check_in: Date.current + 3, check_out: Date.current + 5, status: :cancelled)

      result = described_class.new.call(check_in: Date.current + 3, check_out: Date.current + 5)

      expect(result.value!.map { |r| r[:id] }).to include(cancelled.id)
    end

    it "excludes rooms under maintenance or cleaning" do
      create(:room, status: :maintenance)
      create(:room, status: :cleaning)
      free = create(:room)

      result = described_class.new.call(check_in: Date.current + 3, check_out: Date.current + 5)

      expect(result.value!.map { |r| r[:id] }).to eq([ free.id ])
    end

    it "excludes rooms in an unavailability window overlapping the range" do
      create(:room, unavailable_from: Date.current, unavailable_until: Date.current + 10)
      free = create(:room)

      result = described_class.new.call(check_in: Date.current + 3, check_out: Date.current + 5)

      expect(result.value!.map { |r| r[:id] }).to eq([ free.id ])
    end

    it "includes rooms whose unavailability window does not overlap" do
      create(:room, unavailable_from: Date.current + 6, unavailable_until: Date.current + 9)

      result = described_class.new.call(check_in: Date.current + 3, check_out: Date.current + 5)

      expect(result.value!.size).to eq(1)
    end

    it "treats the exclude_room_id room as free even with an overlapping booking" do
      room = create(:room)
      create(:booking, room: room, check_in: Date.current + 3, check_out: Date.current + 5)

      result = described_class.new.call(
        check_in: Date.current + 3,
        check_out: Date.current + 5,
        exclude_room_id: room.id
      )

      expect(result.value!.map { |r| r[:id] }).to eq([ room.id ])
    end

    it "fails with :invalid_dates when check_in cannot be parsed" do
      result = described_class.new.call(check_in: "not-a-date", check_out: Date.current + 5)

      expect(result).to be_failure
      expect(result.failure).to eq(:invalid_dates)
    end

    it "fails with :invalid_dates when check_out cannot be parsed" do
      result = described_class.new.call(check_in: Date.current + 3, check_out: "not-a-date")

      expect(result).to be_failure
      expect(result.failure).to eq(:invalid_dates)
    end

    it "fails with :invalid_range when the range is inverted" do
      result = described_class.new.call(check_in: Date.current + 5, check_out: Date.current + 3)

      expect(result).to be_failure
      expect(result.failure).to eq(:invalid_range)
    end

    it "fails with :invalid_range when dates are equal" do
      result = described_class.new.call(check_in: Date.current + 3, check_out: Date.current + 3)

      expect(result).to be_failure
      expect(result.failure).to eq(:invalid_range)
    end

    it "successfully returns a room for an unoccupied single night" do
      room = create(:room)

      result = described_class.new.call(check_in: Date.current + 3, check_out: Date.current + 4)

      expect(result).to be_success
      expect(result.value!.map { |r| r[:id] }).to eq([ room.id ])
    end

    it "fails with a message when a closed date falls within the stay" do
      create(:closed_date, date: Date.current + 4)

      result = described_class.new.call(check_in: Date.current + 3, check_out: Date.current + 5)

      expect(result).to be_failure
      expect(result.failure).to eq("Отель закрыт на выбранные даты")
    end

    it "ignores a closed date on the check_out day" do
      create(:closed_date, date: Date.current + 5)
      create(:room)

      result = described_class.new.call(check_in: Date.current + 3, check_out: Date.current + 5)

      expect(result).to be_success
    end

    it "fails with a message when the stay is shorter than the period minimum" do
      create(:price_period, starts_on: Date.current + 3, ends_on: Date.current + 9, min_nights: 3)

      result = described_class.new.call(check_in: Date.current + 3, check_out: Date.current + 5)

      expect(result).to be_failure
      expect(result.failure).to eq("Минимальный срок проживания — 3 ночи")
    end

    it "succeeds when the stay meets the period minimum" do
      create(:price_period, starts_on: Date.current + 3, ends_on: Date.current + 9, min_nights: 3)
      create(:room)

      result = described_class.new.call(check_in: Date.current + 3, check_out: Date.current + 7)

      expect(result).to be_success
    end
  end
end
