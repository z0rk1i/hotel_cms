require 'rails_helper'

RSpec.describe Booking, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:booking)).to be_valid
    end

    it "requires check_in and check_out" do
      booking = build(:booking, check_in: nil, check_out: nil)
      expect(booking).to be_invalid
      expect(booking.errors[:check_in]).to be_present
      expect(booking.errors[:check_out]).to be_present
    end

    it "rejects check_out before check_in" do
      booking = build(:booking, check_in: Date.current, check_out: Date.current)
      expect(booking).to be_invalid
      expect(booking.errors[:check_out]).to include("должна быть позже даты заезда")
    end

    it "rejects guests count above room capacity" do
      booking = build(:booking, guests_count: 99)
      expect(booking).to be_invalid
      expect(booking.errors[:guests_count]).to include("превышает вместимость номера")
    end
  end

  describe "date overlap" do
    let!(:booking) { create(:booking, check_in: Date.current + 3, check_out: Date.current + 5) }

    it "rejects an overlapping booking for the same room" do
      overlap = build(:booking, room: booking.room, check_in: Date.current + 4, check_out: Date.current + 6)
      expect(overlap).to be_invalid
      expect(overlap.errors[:room]).to include("уже забронирован на выбранные даты")
    end

    it "rejects a booking fully contained in an existing one" do
      overlap = build(:booking, room: booking.room, check_in: Date.current + 3, check_out: Date.current + 5)
      expect(overlap).to be_invalid
    end

    it "allows adjacent bookings (check_out == next check_in)" do
      adjacent = build(:booking, room: booking.room, check_in: booking.check_out, check_out: booking.check_out + 2)
      expect(adjacent).to be_valid
    end

    it "allows a booking for a different room on the same dates" do
      other_room = create(:room)
      other = build(:booking, room: other_room, check_in: booking.check_in, check_out: booking.check_out)
      expect(other).to be_valid
    end

    it "ignores cancelled bookings when checking overlap" do
      cancelled = create(:booking, :cancelled, room: booking.room,
                                        check_in: booking.check_in, check_out: booking.check_out)
      expect(cancelled).to be_valid
      expect(booking.room.occupied_during?(booking.check_in, booking.check_out, exclude_booking: booking)).to be(false)
    end

    it "excludes itself when validating an update" do
      booking.update!(check_out: booking.check_out + 1)
      expect(booking).to be_valid
    end
  end

  describe "price calculation" do
    it "computes total price from nights and room rate" do
      room = create(:room, price_per_night: 1000)
      booking = create(:booking, room: room, check_in: Date.current + 1, check_out: Date.current + 4)
      expect(booking.nights).to eq(3)
      expect(booking.total_price).to eq(3000)
    end

    it "recalculates price when dates change" do
      room = create(:room, price_per_night: 1000)
      booking = create(:booking, room: room, check_in: Date.current + 1, check_out: Date.current + 2)
      booking.update!(check_out: Date.current + 5)
      expect(booking.total_price).to eq(4000)
    end

    it "recalculates price when the room changes" do
      room = create(:room, price_per_night: 1000)
      expensive = create(:room, price_per_night: 2000)
      booking = create(:booking, room: room, check_in: Date.current + 1, check_out: Date.current + 2)
      booking.update!(room: expensive)
      expect(booking.reload.total_price).to eq(2000)
    end

    it "preserves a manually adjusted total price on unrelated updates" do
      room = create(:room, price_per_night: 1000)
      booking = create(:booking, room: room, check_in: Date.current + 1, check_out: Date.current + 2)
      booking.update!(total_price: 500)
      booking.update!(notes: "Скидка")

      expect(booking.reload.total_price).to eq(500)
    end
  end

  describe "price snapshot" do
    it "freezes the nightly breakdown on create" do
      room = create(:room, price_per_night: 1000)
      booking = create(:booking, room: room, check_in: Date.current + 1, check_out: Date.current + 4)

      expect(booking.nightly_prices.map(&:amount)).to eq([ 1000, 1000, 1000 ])
      expect(booking.nightly_prices.map(&:date)).to eq([ Date.current + 1, Date.current + 2, Date.current + 3 ])
      expect(booking.price_frozen_on).to eq(Date.current)
    end

    it "does not change the price when the tariff changes later" do
      room = create(:room, price_per_night: 1000)
      booking = create(:booking, room: room, check_in: Date.current + 10, check_out: Date.current + 12)
      expect(booking.total_price).to eq(2000)

      room.update!(price_per_night: 5000)
      create(:price_period, starts_on: Date.current + 10, ends_on: Date.current + 12, multiplier: 3)

      expect(booking.reload.total_price).to eq(2000)
      expect(booking.nightly_prices.map(&:amount)).to eq([ 1000, 1000 ])
    end

    it "updates the snapshot when dates change" do
      room = create(:room, price_per_night: 1000)
      booking = create(:booking, room: room, check_in: Date.current + 1, check_out: Date.current + 2)
      booking.update!(check_out: Date.current + 5)

      expect(booking.reload.total_price).to eq(4000)
      expect(booking.nightly_prices.count).to eq(4)
    end

    it "keeps the snapshot on unrelated updates" do
      room = create(:room, price_per_night: 1000)
      booking = create(:booking, room: room, check_in: Date.current + 1, check_out: Date.current + 2)
      booking.update!(notes: "Квитанция")

      expect(booking.total_price).to eq(1000)
      expect(booking.nightly_prices.count).to eq(1)
      expect(booking.price_frozen_on).to eq(Date.current)
    end
  end

  describe "payments" do
    it "computes paid and due amounts" do
      room = create(:room, price_per_night: 2500)
      booking = create(:booking, room: room, check_in: Date.current + 1, check_out: Date.current + 4)

      expect(booking.total_price).to eq(7500)
      expect(booking.paid_amount).to eq(0)
      expect(booking.due_amount).to eq(7500)

      create(:payment, booking: booking, amount: 1500)
      create(:payment, booking: booking, amount: 2500)

      expect(booking.paid_amount).to eq(4000)
      expect(booking.due_amount).to eq(3500)
    end

    it "does not destroy a booking that has payments" do
      booking = create(:booking)
      create(:payment, booking: booking)

      expect { booking.destroy }.not_to change(Booking, :count)
      expect(booking.errors[:base]).to be_present
    end

    it "includes a no-show fee in the due amount" do
      booking = create(:booking)
      booking.update!(total_price: 3000, no_show_fee: 1000)
      create(:payment, booking: booking, amount: 500)

      expect(booking.due_amount).to eq(3500)
    end
  end

  describe "scopes" do
    it "excludes cancelled from active" do
      create(:booking)
      create(:booking, :cancelled)
      expect(Booking.active.count).to eq(1)
    end

    it "finds active_overlapping ranges" do
      create(:booking, check_in: Date.current + 3, check_out: Date.current + 5)
      expect(Booking.active_overlapping(Date.current + 4, Date.current + 6).count).to eq(1)
      expect(Booking.active_overlapping(Date.current + 6, Date.current + 8).count).to eq(0)
    end
  end

  describe "notifications" do
    it "notifies the user when the status changes" do
      booking = create(:booking, user: create(:user))
      expect { booking.confirmed! }.to change(booking.user.notifications, :count).by(1)
      notification = booking.user.notifications.last
      expect(notification.notifiable).to eq(booking)
      expect(notification.kind).to eq("booking_status")
      expect(notification.title).to include("брони №#{booking.id}")
    end

    it "does not notify when the booking has no user" do
      booking = create(:booking)
      expect { booking.confirmed! }.not_to change(Notification, :count)
    end

    it "does not notify when status is unchanged" do
      booking = create(:booking, :confirmed, user: create(:user))
      expect { booking.update(notes: "Обновлено") }.not_to change(Notification, :count)
    end
  end

  describe "guests count" do
    it "rejects a guests count below 1" do
      expect(build(:booking, guests_count: 0)).to be_invalid
      expect(build(:booking, guests_count: nil)).to be_valid
    end
  end

  describe "room unavailability window" do
    it "rejects a booking overlapping the room's unavailability window" do
      room = create(:room, unavailable_from: Date.current + 1, unavailable_until: Date.current + 10)
      booking = build(:booking, room: room, check_in: Date.current + 5, check_out: Date.current + 7)
      expect(booking).to be_invalid
      expect(booking.errors[:room]).to include("недоступен для бронирования на выбранные даты")
    end

    it "allows a booking outside the unavailability window" do
      room = create(:room, unavailable_from: Date.current + 1, unavailable_until: Date.current + 5)
      booking = build(:booking, room: room, check_in: Date.current + 6, check_out: Date.current + 8)
      expect(booking).to be_valid
    end
  end

  describe "status transitions" do
    it "allows legal transitions" do
      booking = create(:booking)
      expect(booking.can_transition_to?(:confirmed)).to be(true)
      booking.confirmed!
      expect(booking.can_transition_to?(:checked_in)).to be(true)
      expect(booking.can_transition_to?(:cancelled)).to be(true)
    end

    it "rejects illegal transitions" do
      booking = create(:booking, :confirmed)
      expect(booking.can_transition_to?(:pending)).to be(false)
      expect(booking.can_transition_to?(:checked_out)).to be(false)
      expect { booking.update!(status: :checked_out) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "does not check in a cancelled booking" do
      booking = create(:booking, :cancelled)
      expect(booking.transition_to(:checked_in)).to be(false)
      expect(booking).to be_cancelled
    end

    it "marks the room occupied when checked in and cleaning when checked out" do
      room = create(:room)
      booking = create(:booking, :confirmed, room: room)
      booking.checked_in!
      expect(room.reload).to be_occupied
      booking.checked_out!
      expect(room.reload).to be_cleaning
    end

    it "records room status changes in the journal" do
      room = create(:room)
      booking = create(:booking, :confirmed, room: room)
      booking.checked_in!
      booking.checked_out!

      logs = room.status_logs.ordered.map { |log| [ log.from_status, log.to_status ] }
      expect(logs).to eq([ [ "occupied", "cleaning" ], [ "available", "occupied" ] ])
    end

    it "frees the room back to available after cancellation" do
      room = create(:room)
      booking = create(:booking, :confirmed, room: room)
      booking.checked_in!
      booking.cancelled!

      expect(room.reload).to be_available
      last_log = room.status_logs.ordered.first
      expect(last_log.from_status).to eq("occupied")
      expect(last_log.to_status).to eq("available")
    end

    it "frees the room when a checked-in booking is cancelled" do
      room = create(:room)
      booking = create(:booking, :checked_in, room: room)
      expect(room.reload).to be_occupied
      booking.cancelled!
      expect(room.reload).to be_available
    end
  end

  describe "service orders" do
    it "cancels pending service orders when the booking is cancelled" do
      user = create(:user)
      booking = create(:booking, :confirmed, user: user, check_in: Date.current + 1, check_out: Date.current + 5)
      pending_order = create(:service_order, user: user, booking: booking, service_date: Date.current + 3)
      confirmed_order = create(:service_order, :confirmed, user: user, booking: booking, service_date: Date.current + 3)

      booking.transition_to(:cancelled)

      expect(pending_order.reload).to be_cancelled
      expect(confirmed_order.reload).to be_confirmed
    end
  end

  describe "database constraints" do
    it "rejects overlapping active bookings at the database level" do
      existing = create(:booking, :confirmed, check_in: Date.current + 10, check_out: Date.current + 12)
      overlap = Booking.new(room: existing.room, guest: existing.guest,
                            check_in: existing.check_in + 1, check_out: existing.check_out + 1)

      expect(overlap.save(validate: false)).to be(false)
      expect(overlap.errors[:room]).to include("уже забронирован на выбранные даты")
    end

    it "allows overlapping cancelled bookings at the database level" do
      existing = create(:booking, :cancelled, check_in: Date.current + 10, check_out: Date.current + 12)
      overlap = Booking.new(room: existing.room, guest: existing.guest,
                            check_in: existing.check_in, check_out: existing.check_out)

      expect(overlap.save(validate: false)).to be(true)
    end

    it "enforces the exclusion constraint via raw SQL" do
      existing = create(:booking, :confirmed, check_in: Date.current + 10, check_out: Date.current + 12)

      expect do
        ActiveRecord::Base.connection.execute(<<~SQL.squish)
          INSERT INTO bookings (room_id, guest_id, check_in, check_out, guests_count, status, total_price, created_at, updated_at)
          VALUES (#{existing.room_id}, #{existing.guest_id}, '#{(existing.check_in + 1).iso8601}', '#{(existing.check_out + 1).iso8601}', 1, 'pending', 0, NOW(), NOW())
        SQL
      end.to raise_error(ActiveRecord::StatementInvalid)
    end
  end
end
