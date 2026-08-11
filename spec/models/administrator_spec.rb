require 'rails_helper'

RSpec.describe Administrator, type: :model do
  subject(:administrator) { build(:administrator) }

  it "is valid with valid attributes" do
    expect(administrator).to be_valid
  end

  it "requires an email" do
    administrator.email = nil
    expect(administrator).to be_invalid
  end
end
