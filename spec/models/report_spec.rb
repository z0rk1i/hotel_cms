require "rails_helper"

RSpec.describe Report, type: :model do
  describe "validations" do
    it "rejects period_end before period_start" do
      report = Report.new(period_start: Date.current, period_end: Date.current - 1, data: {})
      expect(report).to be_invalid
    end
  end

  describe ".refresh!" do
    it "builds data for a period and stores it" do
      room = create(:room, price_per_night: 1000, weekend_multiplier: 1.0)
      create(:stay, :confirmed, room: room, check_in: Date.current + 1, check_out: Date.current + 3)

      from = Date.current.beginning_of_month
      to = Date.current.end_of_month
      report = described_class.refresh!(from: from, to: to)

      expect(report.kind).to eq("month")
      expect(report.plan_revenue).to eq(2000)
      expect(report.fact_revenue).to eq(0)
      expect(report.booked_nights).to eq(2)
      expect(report.capacity_nights).to eq(Room.count * (to - from).to_i)
    end

    it "upserts the same period instead of duplicating" do
      from = Date.current.beginning_of_month
      to = Date.current.end_of_month
      described_class.refresh!(from: from, to: to)
      described_class.refresh!(from: from, to: to)
      expect(Report.where(kind: "month").size).to eq(1)
    end
  end

  describe ".range_kind" do
    it "returns month for full calendar months" do
      expect(described_class.range_kind(Date.current.beginning_of_month, Date.current.end_of_month)).to eq("month")
      expect(described_class.range_kind(Date.current, Date.current + 1)).to eq("custom")
    end
  end
end
