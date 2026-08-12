require "rails_helper"

RSpec.describe StayRules do
  describe ".min_nights_between" do
    it "returns 0 when no period imposes a minimum" do
      expect(described_class.min_nights_between(check_in: Date.current + 1, check_out: Date.current + 3)).to eq(0)
    end

    it "returns the maximum min_nights among overlapping periods" do
      create(:price_period, starts_on: Date.current + 1, ends_on: Date.current + 5, min_nights: 2)
      create(:price_period, starts_on: Date.current + 6, ends_on: Date.current + 10, min_nights: 4)

      expect(described_class.min_nights_between(check_in: Date.current + 1, check_out: Date.current + 7)).to eq(4)
    end

    it "ignores periods without min_nights" do
      create(:price_period, starts_on: Date.current + 1, ends_on: Date.current + 5)
      expect(described_class.min_nights_between(check_in: Date.current + 1, check_out: Date.current + 3)).to eq(0)
    end

    it "considers a period that only partially overlaps the stay" do
      create(:price_period, starts_on: Date.current + 2, ends_on: Date.current + 4, min_nights: 3)
      expect(described_class.min_nights_between(check_in: Date.current + 1, check_out: Date.current + 6)).to eq(3)
    end
  end

  describe ".closed_dates_between" do
    it "returns closed nights within the stay" do
      create(:closed_date, date: Date.current + 1)
      create(:closed_date, date: Date.current + 3)
      create(:closed_date, date: Date.current + 10)

      closed = described_class.closed_dates_between(check_in: Date.current, check_out: Date.current + 4)
      expect(closed).to eq([ Date.current + 1, Date.current + 3 ])
    end

    it "excludes the check_out day" do
      create(:closed_date, date: Date.current + 2)
      expect(described_class.closed_dates_between(check_in: Date.current, check_out: Date.current + 2)).to be_empty
    end
  end

  describe ".closed_in?" do
    it "is true when a closed night falls in the stay" do
      create(:closed_date, date: Date.current + 3)
      expect(described_class).to be_closed_in(check_in: Date.current, check_out: Date.current + 5)
    end

    it "is false otherwise" do
      create(:closed_date, date: Date.current + 10)
      expect(described_class).not_to be_closed_in(check_in: Date.current, check_out: Date.current + 5)
    end
  end
end
