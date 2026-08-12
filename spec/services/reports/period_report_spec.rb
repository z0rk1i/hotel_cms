require "rails_helper"

RSpec.describe Reports::PeriodReport, type: :model do
  let(:from) { Date.current + 1 }
  let(:to) { from + 2 }

  describe "#night_rows" do
    it "reports plan revenue, real payments, sold rooms and total rooms per night" do
      room = create(:room)
      booking = create(:booking, :confirmed, room: room, check_in: from, check_out: from + 2)
      create(:payment, booking: booking, amount: 1500, paid_at: from.beginning_of_day + 1.hour)

      report = described_class.new(from: from, to: to)

      plan = booking.nightly_prices.find_by(date: from).amount
      rows = report.night_rows

      expect(rows.size).to eq(3)
      expect(rows.map { |row| row[:sold] }).to eq([ 1, 1, 0 ])
      expect(rows[0][:plan]).to eq(plan)
      expect(rows[1][:plan]).to eq(plan)
      expect(rows[0][:fact]).to eq(1500)
      expect(rows[0][:total]).to eq(Room.count)
    end

    it "excludes cancelled and pending bookings" do
      cancelled_room = create(:room)
      pending_room = create(:room)
      create(:booking, :cancelled, room: cancelled_room, check_in: from - 2, check_out: from + 2)
      create(:booking, room: pending_room, check_in: from - 2, check_out: from + 2)

      rows = described_class.new(from: from, to: to).night_rows

      expect(rows.map { |row| row[:sold] }).to all(eq(0))
    end
  end

  describe "#category_rows" do
    it "computes capacity, sold nights and occupancy per category" do
      category = create(:room_category)
      rooms = create_list(:room, 2, category: category)
      create(:booking, :confirmed, room: rooms.first, check_in: from, check_out: from + 2)

      rows = described_class.new(from: from, to: to).category_rows

      row = rows.detect { |r| r[:category] == category }
      expect(row[:rooms]).to eq(2)
      expect(row[:capacity_nights]).to eq(6)
      expect(row[:sold_nights]).to eq(2)
      expect(row[:occupancy]).to be_within(0.1).of(33.3)
    end
  end

  describe "#summary" do
    it "totals fact, plan and average occupancy" do
      room = create(:room)
      booking = create(:booking, :confirmed, room: room, check_in: from, check_out: from + 2)
      create(:payment, booking: booking, amount: 2000, paid_at: from.beginning_of_day + 1.hour)

      report = described_class.new(from: from, to: to)

      expect(report.summary[:fact]).to eq(2000)
      expect(report.summary[:plan]).to eq(booking.nightly_prices.sum(:amount))
      expect(report.summary[:occupancy]).to be_within(0.1).of(66.7)
    end
  end

  describe "range guard" do
    it "clamps a too-long period to 92 days" do
      report = described_class.new(from: Date.current, to: Date.current + 200)
      expect(report.to).to eq(Date.current + Reports::PeriodReport::MAX_RANGE_DAYS)
    end
  end
end
