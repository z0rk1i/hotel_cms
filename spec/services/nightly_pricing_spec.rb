require 'rails_helper'

RSpec.describe NightlyPricing do
  let(:room) { create(:room, price_per_night: 1000) }

  describe "#total" do
    it "sums base prices for a stay without periods or weekend uplift" do
      pricing = described_class.new(room: room, check_in: Date.current, check_out: Date.current + 3)
      expect(pricing.total).to eq(3000)
    end

    it "applies the seasonal multiplier for covered nights" do
      create(:price_period, starts_on: Date.current + 1, ends_on: Date.current + 5, multiplier: 2)
      pricing = described_class.new(room: room, check_in: Date.current, check_out: Date.current + 3)
      expect(pricing.total).to eq(1000 + 2000 + 2000)
    end

    it "applies the weekend multiplier on Friday and Saturday nights" do
      room.update!(weekend_multiplier: 1.5)
      friday = Date.new(2026, 8, 14)
      saturday = Date.new(2026, 8, 15)
      expect(friday.wday).to eq(5)
      expect(saturday.wday).to eq(6)

      pricing = described_class.new(room: room, check_in: friday, check_out: friday + 2)
      expect(pricing.total).to eq(1500 + 1500)
    end

    it "does not apply the weekend multiplier on weekdays" do
      room.update!(weekend_multiplier: 1.5)
      monday = Date.new(2026, 8, 17)
      expect(monday.wday).to eq(1)

      pricing = described_class.new(room: room, check_in: monday, check_out: monday + 1)
      expect(pricing.total).to eq(1000)
    end

    it "combines seasonal and weekend multipliers" do
      room.update!(weekend_multiplier: 1.2)
      friday = Date.new(2026, 8, 14)
      create(:price_period, starts_on: friday, ends_on: friday + 10, multiplier: 1.5)

      pricing = described_class.new(room: room, check_in: friday, check_out: friday + 1)
      expect(pricing.total).to eq((1000 * 1.5 * 1.2).to_i)
    end

    it "exposes per-night entries" do
      pricing = described_class.new(room: room, check_in: Date.current, check_out: Date.current + 2)
      expect(pricing.entries.map(&:amount)).to eq([ 1000, 1000 ])
      expect(pricing.entries.first.date).to eq(Date.current)
    end
  end
end
