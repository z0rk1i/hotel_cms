require "rails_helper"

RSpec.describe Payment, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:payment)).to be_valid
    end

    it "requires a positive amount" do
      expect(build(:payment, amount: nil)).to be_invalid
      expect(build(:payment, amount: 0)).to be_invalid
      expect(build(:payment, amount: -100)).to be_invalid
    end

    it "requires paid_at" do
      expect(build(:payment, paid_at: nil)).to be_invalid
    end

    it "accepts all payment methods" do
      expect(build(:payment, method: :cash)).to be_valid
      expect(build(:payment, method: :card)).to be_valid
      expect(build(:payment, method: :transfer)).to be_valid
    end
  end
end
