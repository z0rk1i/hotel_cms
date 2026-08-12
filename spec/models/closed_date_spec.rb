require "rails_helper"

RSpec.describe ClosedDate, type: :model do
  it "is valid with a unique date" do
    expect(build(:closed_date)).to be_valid
  end

  it "requires a date" do
    expect(build(:closed_date, date: nil)).not_to be_valid
  end

  it "rejects a duplicate date" do
    create(:closed_date, date: Date.current + 5)
    expect(build(:closed_date, date: Date.current + 5)).not_to be_valid
  end

  it "lists dates chronologically" do
    later = create(:closed_date, date: Date.current + 10)
    earlier = create(:closed_date, date: Date.current + 2)
    expect(described_class.ordered.to_a).to eq([ earlier, later ])
  end
end
