require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:user)).to be_valid
    end

    it "requires email and format for admins" do
      expect(build(:user, :admin, email: nil)).to be_invalid
      expect(build(:user, :admin, email: "not-an-email")).to be_invalid
    end

    it "does not require email for guests" do
      expect(build(:user, email: nil)).to be_valid
    end

    it "requires full_name for guests" do
      expect(build(:user, full_name: nil)).to be_invalid
    end

    it "rejects duplicate emails case-insensitively" do
      create(:user, email: "Ivan@example.com")
      expect(build(:user, email: "ivan@example.com")).to be_invalid
    end

    it "validates phone format" do
      expect(build(:user, phone: "abc")).to be_invalid
    end
  end

  describe "roles" do
    it "exposes admin? and guest?" do
      expect(build(:user, :admin)).to be_admin
      expect(build(:user)).to be_guest
    end

    it "scopes admins and guests" do
      admin = create(:user, :admin)
      guest = create(:user)

      expect(User.admins).to include(admin)
      expect(User.admins).not_to include(guest)
      expect(User.guests).to include(guest)
    end
  end

  describe "consent" do
    it "has_consent? reflects consent_signed_at" do
      expect(build(:user)).not_to have_consent
      expect(build(:user, :with_consent)).to have_consent
    end

    it "confirm_consent! records the timestamp once" do
      user = create(:user)
      user.confirm_consent!
      first = user.consent_signed_at
      user.confirm_consent!
      expect(user.consent_signed_at).to eq(first)
    end
  end

  describe "aggregates" do
    it "computes paid_amount, due_amount, total_spent and stays_count" do
      user = create(:user)
      past = create(:stay, :checked_out, user: user)
      past.update!(total_price: 10_000)
      past.add_payment!(method: "cash", amount: 6_000)
      active = create(:stay, :confirmed, user: user)
      active.update!(total_price: 4_000)

      expect(user.paid_amount).to eq(6_000)
      expect(user.due_amount).to eq(4_000)
      expect(user.total_spent).to eq(10_000)
      expect(user.stays_count).to eq(1)
    end
  end

  describe "search" do
    it "finds users by name, phone or email" do
      ivan = create(:user, full_name: "Иван Петров", phone: "+7 900 000-00-01")
      create(:user, full_name: "Мария Иванова", phone: "+7 900 000-00-02")

      expect(User.search("Иван")).to include(ivan)
      expect(User.search("+7 900 000-00-01")).to include(ivan)
    end
  end

  describe "#merge_into!" do
    it "moves stays to the target and destroys the source" do
      source = create(:user)
      target = create(:user)
      stay = create(:stay, :confirmed, user: source)

      result = source.merge_into!(target)

      expect(stay.reload.user).to eq(target)
      expect { source.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(result).to eq(target)
    end
  end

  describe "#letter_avatar" do
    it "returns the first letter of the first name" do
      expect(create(:user, full_name: "Иван Петров").letter_avatar).to eq("И")
    end
  end
end
