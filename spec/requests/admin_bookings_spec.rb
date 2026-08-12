require 'rails_helper'

RSpec.describe "Admin bookings", type: :request do
  before { sign_in create(:administrator) }

  describe "status transitions" do
    it "confirms a pending booking" do
      booking = create(:booking)
      patch confirm_admin_booking_path(booking)
      expect(booking.reload).to be_confirmed
    end

    it "checks in a confirmed booking and marks the room occupied" do
      booking = create(:booking, :confirmed)
      patch check_in_admin_booking_path(booking)
      expect(booking.reload).to be_checked_in
      expect(booking.room.reload).to be_occupied
    end

    it "checks out and frees the room" do
      booking = create(:booking, :checked_in)
      patch check_out_admin_booking_path(booking)
      expect(booking.reload).to be_checked_out
      expect(booking.room.reload).to be_available
    end

    it "cancels a booking" do
      booking = create(:booking, :confirmed)
      patch cancel_admin_booking_path(booking)
      expect(booking.reload).to be_cancelled
    end

    it "does not check in a cancelled booking" do
      booking = create(:booking, :cancelled)
      patch check_in_admin_booking_path(booking)
      expect(booking.reload).to be_cancelled
      expect(booking.room.reload).to be_available
    end

    it "frees the room when cancelling a checked-in booking" do
      booking = create(:booking, :checked_in)
      expect(booking.room.reload).to be_occupied
      patch cancel_admin_booking_path(booking)
      expect(booking.reload).to be_cancelled
      expect(booking.room.reload).to be_available
    end
  end

  describe "audit trail" do
    it "records the acting administrator on admin transitions" do
      admin = Administrator.last
      booking = create(:booking)
      patch confirm_admin_booking_path(booking)

      log = booking.audit_logs.last
      expect(log.administrator).to eq(admin)
      expect(log.from_status).to eq("pending")
      expect(log.to_status).to eq("confirmed")
    end

    it "shows the history on the booking page" do
      booking = create(:booking)
      patch confirm_admin_booking_path(booking)

      get admin_booking_path(booking)
      expect(response.body).to include("История изменений")
      expect(response.body).to include(Administrator.last.email)
    end
  end

  describe "CSV export" do
    it "exports all bookings as CSV" do
      room = create(:room, price_per_night: 2000, capacity: 2)
      create(:booking, :confirmed, guests_count: 2, room: room)
      create(:booking, :cancelled)

      get admin_bookings_path(format: :csv)

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to include("text/csv")

      rows = CSV.parse(response.body)
      expect(rows.length).to eq(3)
      expect(rows.first).to include("Гость", "Статус", "Оплачено, ₽", "Долг, ₽")
      expect(rows.map { |r| r[9] }).to include("4000.0")
      expect(rows.map { |r| r[12] }).to include("подтверждена", "отменена")
    end

    it "exports paid and due amounts" do
      booking = create(:booking, :confirmed)
      create(:payment, booking: booking, amount: 500)

      get admin_bookings_path(format: :csv)

      rows = CSV.parse(response.body)
      expect(rows.last[9]).to eq(booking.total_price.to_s)
      expect(rows.last[10]).to eq("500.0")
      expect(rows.last[11]).to eq((booking.total_price - 500).to_s)
    end

    it "respects the status filter" do
      create(:booking, :confirmed)
      create(:booking, :cancelled)

      get admin_bookings_path(format: :csv, status: "confirmed")

      rows = CSV.parse(response.body)
      expect(rows.length).to eq(2)
      expect(rows.last[12]).to eq("подтверждена")
    end
  end

  describe "booking creation" do
    it "rejects a booking for an already occupied room" do
      existing = create(:booking, check_in: Date.current + 3, check_out: Date.current + 5)
      guest = create(:guest)
      post admin_bookings_path, params: {
        booking: {
          guest_id: guest.id,
          room_id: existing.room.id,
          check_in: Date.current + 4,
          check_out: Date.current + 6,
          guests_count: 1
        }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "creates a booking and computes the price" do
      room = create(:room, price_per_night: 2000)
      guest = create(:guest)
      expect {
        post admin_bookings_path, params: {
          booking: {
            guest_id: guest.id,
            room_id: room.id,
            check_in: Date.current + 5,
            check_out: Date.current + 7,
            guests_count: 1
          }
        }
      }.to change(Booking, :count).by(1)
      expect(Booking.last.total_price).to eq(4000)
    end

    it "does not create an admin bell notification for an admin-created booking" do
      room = create(:room)
      guest = create(:guest)
      expect do
        post admin_bookings_path, params: {
          booking: {
            guest_id: guest.id,
            room_id: room.id,
            check_in: Date.current + 5,
            check_out: Date.current + 7,
            guests_count: 1
          }
        }
      end.to change(Booking, :count).by(1)
      expect(Notification.for_admin).to be_empty
    end
  end
end
