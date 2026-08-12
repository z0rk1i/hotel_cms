require 'rails_helper'

RSpec.describe Guest, type: :model do
  it "is valid with valid attributes" do
    expect(build(:guest)).to be_valid
  end

  it "requires a full name" do
    expect(build(:guest, full_name: nil)).to be_invalid
  end

  it "rejects malformed emails" do
    expect(build(:guest, email: "not-an-email")).to be_invalid
  end

  it "allows blank email" do
    expect(build(:guest, email: nil)).to be_valid
  end

  describe ".search" do
    it "finds guests by name substring" do
      guest = create(:guest, full_name: "Анна Смирнова")
      expect(Guest.search("смирн")).to include(guest)
    end

    it "finds guests by phone substring" do
      guest = create(:guest, phone: "+7 900 123-45-67")
      expect(Guest.search("123-45")).to include(guest)
    end

    it "returns all when query is blank" do
      expect(Guest.search("")).to eq(Guest.all)
    end
  end

  describe "#total_spent" do
    it "sums payments across all bookings" do
      guest = create(:guest)
      booking = create(:booking, guest: guest)
      create(:payment, booking: booking, amount: 1500)
      create(:payment, booking: booking, amount: 2500)

      expect(guest.total_spent).to eq(4000)
    end

    it "is zero when there are no payments" do
      guest = create(:guest)

      expect(guest.total_spent).to eq(0)
    end
  end

  describe "#possible_duplicates" do
    it "finds guests sharing an email regardless of case" do
      guest = create(:guest, email: "Same@Example.com", phone: nil, passport_number: nil)
      duplicate = create(:guest, email: "same@example.com", phone: nil, passport_number: nil)
      create(:guest)

      expect(guest.possible_duplicates).to contain_exactly(duplicate)
    end

    it "finds guests sharing a phone" do
      guest = create(:guest, email: nil, passport_number: nil, phone: "12345")
      duplicate = create(:guest, email: nil, passport_number: nil, phone: "12345")

      expect(guest.possible_duplicates).to contain_exactly(duplicate)
    end

    it "returns none when identities are only blank" do
      guest = create(:guest, email: nil, phone: nil, passport_number: nil)
      create(:guest, email: nil, phone: nil, passport_number: nil)

      expect(guest.possible_duplicates).to be_empty
    end
  end

  describe "#merge_into!" do
    it "moves bookings, merges profile and deletes the duplicate" do
      keep = create(:guest, email: "keep@example.com", phone: nil, passport_number: nil, notes: "Любит 2 этаж")
      duplicate = create(:guest, email: nil, phone: "999", passport_number: nil, notes: "Аллергия на пух", is_vip: true)
      booking = create(:booking, guest: duplicate)

      expect(duplicate.merge_into!(keep)).to be(true)

      expect(booking.reload.guest_id).to eq(keep.id)
      expect(keep.is_vip).to be(true)
      expect(keep.phone).to eq("999")
      expect(keep.notes).to include("Любит 2 этаж", "Аллергия на пух")
      expect(Guest.exists?(duplicate.id)).to be(false)
    end

    it "refuses to merge a guest into itself" do
      guest = create(:guest)

      expect(guest.merge_into!(guest)).to be(false)
    end
  end
end
