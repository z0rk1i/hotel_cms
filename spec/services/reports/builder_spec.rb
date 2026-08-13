require "rails_helper"

RSpec.describe Reports::Builder, type: :service do
  let(:from) { Date.current.change(day: 1) }
  let(:to) { from + 3.days }

  describe ".build" do
    it "aggregates plan revenue from frozen price breakdowns" do
      room = create(:room, price_per_night: 1000, weekend_multiplier: 1.0)
      create(:stay, :confirmed, room: room, check_in: from, check_out: from + 2.days)

      data = described_class.build(from: from, to: to)

      expect(data["plan_revenue"]).to eq(2000)
      expect(data["booked_nights"]).to eq(2)
      expect(data["capacity_nights"]).to eq(Room.count * 3)
    end

    it "counts real payments as fact revenue" do
      room = create(:room)
      stay = create(:stay, :checked_out, room: room, check_in: from - 1.day, check_out: from + 1.day, total_price: 4000)
      stay.add_payment!(method: "card", amount: 2500, paid_at: from.beginning_of_day + 1.hour)

      data = described_class.build(from: from, to: to)

      expect(data["fact_revenue"]).to eq(2500)
    end

    it "excludes cancelled and pending stays" do
      create(:stay, :cancelled, check_in: from, check_out: from + 1.day)
      create(:stay, check_in: from, check_out: from + 1.day)

      data = described_class.build(from: from, to: to)

      expect(data["booked_nights"]).to eq(0)
    end

    it "groups plan revenue and nights by room category" do
      std = create(:room, category: "Стандарт", price_per_night: 1000, weekend_multiplier: 1.0)
      lux = create(:room, category: "Люкс", price_per_night: 3000, weekend_multiplier: 1.0)
      create(:stay, :confirmed, room: std, check_in: from, check_out: from + 1.day)
      create(:stay, :confirmed, room: lux, check_in: from, check_out: from + 1.day)

      data = described_class.build(from: from, to: to)

      expect(data["by_category"]["Стандарт"]["plan"]).to eq(1000)
      expect(data["by_category"]["Стандарт"]["nights"]).to eq(1)
      expect(data["by_category"]["Люкс"]["plan"]).to eq(3000)
    end
  end
end
