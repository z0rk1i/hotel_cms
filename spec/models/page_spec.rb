require 'rails_helper'

RSpec.describe Page, type: :model do
  it "is valid with valid attributes" do
    expect(build(:page)).to be_valid
  end

  it "requires a title" do
    expect(build(:page, title: nil)).to be_invalid
  end

  it "requires a unique slug" do
    create(:page, slug: "about")
    expect(build(:page, slug: "about")).to be_invalid
  end

  it "parameterizes a messy slug" do
    page = create(:page, slug: "О Гостинице!")
    expect(page.reload.slug).to eq("o-gostinitse")
  end
end
