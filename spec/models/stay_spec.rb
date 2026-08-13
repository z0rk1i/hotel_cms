require "rails_helper"

RSpec.describe Stay, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:stay)).to be_valid
    end

    it "requires check_in before check_out" do
      expect(build(:stay, check_in: Date.current + 3, check_out: Date.current + 1)).to be_invalid
    end

    it "rejects overlapping stays for the same room" do
      room = create(:room)
      create(:stay, room: room, check_in: Date.current + 1, check_out: Date.current + 3)
      stay = build(:stay, room: room, check_in: Date.current + 2, check_out: Date.current + 4)
      expect(stay).to be_invalid
    end

    it "allows adjacent stays (check_out == next check_in)" do
      room = create(:room)
      create(:stay, room: room, check_in: Date.current + 1, check_out: Date.current + 3)
      stay = build(:stay, room: room, check_in: Date.current + 3, check_out: Date.current + 5)
      expect(stay).to be_valid
    end

    it "rejects guests_count beyond room capacity" do
      room = create(:room, capacity: 2)
      expect(build(:stay, room: room, guests_count: 3)).to be_invalid
    end

    it "rejects booking a maintenance room" do
      room = create(:room, :maintenance)
      expect(build(:stay, room: room)).to be_invalid
    end
  end

  describe "pricing" do
    it "freezes nightly breakdown on create" do
      room = create(:room, price_per_night: 1000, weekend_multiplier: 1.0)
      stay = create(:stay, room: room, check_in: Date.new(2026, 8, 10), check_out: Date.new(2026, 8, 13))

      expect(stay.total_price).to eq(3000)
      expect(stay.price_breakdown.size).to eq(3)
      expect(stay.price_frozen_on).to eq(Date.current)
    end

    it "re-freezes prices when dates change" do
      room = create(:room, price_per_night: 1000, weekend_multiplier: 1.0)
      stay = create(:stay, room: room, check_in: Date.new(2026, 8, 10), check_out: Date.new(2026, 8, 12))

      stay.update!(check_out: Date.new(2026, 8, 14))

      expect(stay.total_price).to eq(4000)
    end
  end

  describe "state transitions" do
    let(:stay) { create(:stay) }

    it "confirm moves pending → confirmed" do
      stay.confirm!
      expect(stay.status).to eq("confirmed")
    end

    it "check_in moves confirmed → checked_in" do
      stay.confirm!
      stay.check_in!
      expect(stay.status).to eq("checked_in")
    end

    it "check_out moves checked_in → checked_out" do
      stay.confirm!
      stay.check_in!
      stay.check_out!
      expect(stay.status).to eq("checked_out")
    end

    it "cancel moves pending → cancelled" do
      stay.cancel!
      expect(stay.status).to eq("cancelled")
    end

    it "rejects illegal transitions" do
      expect { stay.check_in! }.to raise_error(ArgumentError)
      expect { stay.check_out! }.to raise_error(ArgumentError)
    end
  end

  describe "payments" do
    let(:stay) { create(:stay, room: create(:room, price_per_night: 2500, weekend_multiplier: 1.0), total_price: 5000) }

    it "tracks paid and due amounts" do
      stay.update!(total_price: 5000)
      stay.add_payment!(method: "cash", amount: 2000)

      expect(stay.paid_amount).to eq(2000)
      expect(stay.due_amount).to eq(3000)
    end

    it "rejects invalid payment method" do
      expect { stay.add_payment!(method: "bitcoin", amount: 100) }.to raise_error(ArgumentError)
    end

    it "removes a payment by id" do
      entry = stay.add_payment!(method: "card", amount: 1000)
      stay.remove_payment!(entry["id"])
      expect(stay.paid_amount).to eq(0)
    end
  end

  describe "services" do
    let(:stay) { create(:stay) }

    it "adds and totals services" do
      stay.add_service!(name: "Завтрак", price: 500, quantity: 2)
      expect(stay.services_total).to eq(1000)
    end

    it "cancels a service" do
      entry = stay.add_service!(name: "Завтрак", price: 500, quantity: 1)
      stay.cancel_service!(entry["id"])
      expect(stay.services_total).to eq(0)
    end
  end

  describe "room state sync" do
    it "marks the room as cleaning on checkout when no other checked-in stays" do
      room = create(:room)
      stay = create(:stay, room: room, check_in: Date.current - 1, check_out: Date.current + 1)

      stay.transition_to!("confirmed")
      stay.transition_to!("checked_in")
      stay.transition_to!("checked_out")

      expect(room.reload.status).to eq("cleaning")
    end

    it "keeps the room occupied when another checked-in stay exists" do
      room = create(:room)
      other = create(:stay, :checked_in, room: room)
      stay = create(:stay, room: room, check_in: Date.current + 5, check_out: Date.current + 7)

      stay.transition_to!("confirmed")
      stay.transition_to!("checked_in")
      stay.transition_to!("checked_out")

      expect(room.reload.status).to eq("occupied")
      expect(other.reload.status).to eq("checked_in")
    end
  end

  describe "scopes" do
    it "active includes pending, confirmed and checked_in" do
      pending = create(:stay)
      confirmed = create(:stay, :confirmed)
      cancelled = create(:stay, :cancelled)

      active = Stay.active
      expect(active).to include(pending, confirmed)
      expect(active).not_to include(cancelled)
    end
  end
end
