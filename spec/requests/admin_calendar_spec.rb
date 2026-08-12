require 'rails_helper'

RSpec.describe "Admin booking calendar", type: :request do
  before { sign_in create(:administrator) }

  describe "GET /admin/bookings/calendar" do
    it "renders the calendar" do
      get calendar_admin_bookings_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Календарь бронирований")
    end

    it "shows a room and its booking for the current month" do
      room = create(:room, number: "500")
      guest = create(:guest, full_name: "Тест Тестов")
      create(:booking, room: room, guest: guest, status: :confirmed,
                       check_in: Date.current.beginning_of_month + 5,
                       check_out: Date.current.beginning_of_month + 7)

      get calendar_admin_bookings_path
      expect(response.body).to include("500")
      expect(response.body).to include("Тест Тестов")
    end

    it "hides cancelled bookings" do
      room = create(:room)
      guest = create(:guest, full_name: "Отменённый Гость")
      create(:booking, room: room, guest: guest, status: :cancelled,
                       check_in: Date.current.beginning_of_month + 5,
                       check_out: Date.current.beginning_of_month + 7)

      get calendar_admin_bookings_path
      expect(response.body).not_to include("Отменённый Гость")
    end

    it "shows bookings that span the month boundary" do
      room = create(:room, number: "600")
      guest = create(:guest, full_name: "Граничный Гость")
      first = Date.current.beginning_of_month
      create(:booking, room: room, guest: guest, status: :confirmed,
                       check_in: first - 2, check_out: first + 2)

      get calendar_admin_bookings_path
      expect(response.body).to include("600")
      expect(response.body).to include("Граничный Гость")
    end

    it "navigates to a requested month" do
      get calendar_admin_bookings_path(month: "2026-06")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Июнь 2026")
    end

    it "falls back to the current month for invalid month params" do
      get calendar_admin_bookings_path(month: "not-a-month")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Date.current.year.to_s)
    end
  end

  describe "GET /admin/bookings/:id" do
    it "renders booking details" do
      room = create(:room)
      guest = create(:guest, full_name: "Детальный Гость")
      booking = create(:booking, room: room, guest: guest, status: :confirmed)

      get admin_booking_path(booking)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Бронь №#{booking.id}")
      expect(response.body).to include("Детальный Гость")
      expect(response.body).to include("Подтверждена")
    end
  end
end
