require "rails_helper"

RSpec.describe DateParams do
  describe ".parse" do
    it "parses ISO dates" do
      expect(described_class.parse("2026-08-15")).to eq(Date.new(2026, 8, 15))
    end

    it "parses Date objects" do
      date = Date.current
      expect(described_class.parse(date)).to eq(date)
    end

    it "returns nil for an unparseable string" do
      expect(described_class.parse("not-a-date")).to be_nil
    end

    it "returns nil for an invalid date" do
      expect(described_class.parse("2026-13-40")).to be_nil
    end

    it "returns nil for an empty string" do
      expect(described_class.parse("")).to be_nil
    end

    it "returns nil for nil" do
      expect(described_class.parse(nil)).to be_nil
    end
  end
end
