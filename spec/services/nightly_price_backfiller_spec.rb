require "rails_helper"

RSpec.describe NightlyPriceBackfiller do
  def legacy_booking(**kwargs)
    booking = create(:booking, **kwargs)
    booking.update_column(:price_frozen_on, nil)
    booking.nightly_prices.delete_all
    booking
  end

  describe ".backfill" do
    it "creates nightly price snapshots and freezes the price date" do
      booking = legacy_booking(room: create(:room, price_per_night: 1000),
                               check_in: Date.current, check_out: Date.current + 3)

      described_class.backfill(booking)

      booking.reload
      expect(booking.nightly_prices.count).to eq(3)
      expect(booking.nightly_prices.map(&:amount).uniq).to eq([ 1000.0 ])
      expect(booking.total_price).to eq(3000.0)
      expect(booking.price_frozen_on).to eq(Date.current)
    end

    it "keeps the invoiced total_price untouched" do
      booking = legacy_booking(room: create(:room, price_per_night: 1000),
                               check_in: Date.current, check_out: Date.current + 3)
      booking.update_column(:total_price, 999_999)

      described_class.backfill(booking)

      expect(booking.reload.total_price).to eq(999_999)
    end

    it "is a no-op when the price is already frozen" do
      booking = create(:booking)
      snapshot_count = booking.nightly_prices.count

      described_class.backfill(booking)

      expect(booking.reload.nightly_prices.count).to eq(snapshot_count)
      expect(booking.price_frozen_on).to eq(Date.current)
    end

    it "replaces partial snapshots instead of hitting the unique index" do
      booking = legacy_booking(room: create(:room),
                               check_in: Date.current, check_out: Date.current + 3)
      booking.nightly_prices.create!(date: booking.check_in, amount: 10)

      described_class.backfill(booking)

      expect(booking.reload.nightly_prices.count).to eq(3)
    end
  end

  describe ".run" do
    it "backfills only bookings without a frozen price" do
      stale = legacy_booking(room: create(:room),
                             check_in: Date.current, check_out: Date.current + 2)
      fresh = create(:booking, room: create(:room),
                     check_in: Date.current + 1, check_out: Date.current + 3)

      described_class.run

      expect(stale.reload.nightly_prices.count).to eq(2)
      expect(stale.reload.price_frozen_on).to eq(Date.current)
      expect(fresh.reload.nightly_prices.count).to eq(2)
    end
  end
end