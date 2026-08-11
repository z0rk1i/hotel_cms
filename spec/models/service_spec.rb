require 'rails_helper'

RSpec.describe Service, type: :model do
  it "is valid with valid attributes" do
    expect(build(:service)).to be_valid
  end

  it "requires a name" do
    expect(build(:service, name: nil)).to be_invalid
  end

  it "rejects negative price" do
    expect(build(:service, price: -1)).to be_invalid
  end

  it "allows nil price" do
    expect(build(:service, price: nil)).to be_valid
  end
end
