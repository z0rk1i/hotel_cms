require 'rails_helper'

RSpec.describe PricePeriod, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:price_period)).to be_valid
    end

    it "requires a name" do
      expect(build(:price_period, name: nil)).to be_invalid
    end

    it "rejects a multiplier of zero or less" do
      expect(build(:price_period, multiplier: 0)).to be_invalid
      expect(build(:price_period, multiplier: -1)).to be_invalid
    end

    it "rejects ends_on before starts_on" do
      period = build(:price_period, starts_on: Date.current + 5, ends_on: Date.current)
      expect(period).to be_invalid
      expect(period.errors[:ends_on]).to include("должна быть позже даты начала")
    end

    it "rejects overlapping periods" do
      create(:price_period, starts_on: Date.current, ends_on: Date.current + 10)
      overlap = build(:price_period, name: "Другой", starts_on: Date.current + 5, ends_on: Date.current + 15)
      expect(overlap).to be_invalid
      expect(overlap.errors[:starts_on]).to include("пересекается с другим периодом")
    end

    it "allows adjacent periods" do
      create(:price_period, starts_on: Date.current, ends_on: Date.current + 10)
      expect(build(:price_period, name: "Другой", starts_on: Date.current + 11, ends_on: Date.current + 20)).to be_valid
    end
  end

  describe ".multiplier_on" do
    it "returns 1 when no period covers the date" do
      expect(PricePeriod.multiplier_on(Date.current + 100)).to eq(1)
    end

    it "returns the multiplier of the covering period" do
      create(:price_period, starts_on: Date.current, ends_on: Date.current + 10, multiplier: 1.5)
      expect(PricePeriod.multiplier_on(Date.current + 5)).to eq(1.5)
      expect(PricePeriod.multiplier_on(Date.current + 11)).to eq(1)
    end
  end
end
