require 'rails_helper'

RSpec.describe "Admin dashboard", type: :request do
  before { sign_in create(:administrator) }

  describe "GET /admin" do
    it "renders the dashboard" do
      get "/admin"
      expect(response).to have_http_status(:ok)
    end

    it "counts rooms booked tonight as unavailable" do
      room = create(:room)
      create(:booking, room: room, status: :confirmed,
                       check_in: Date.current, check_out: Date.current + 2)

      get "/admin"
      expect(response.body).to include("0 / 1")
    end

    it "does not count pending bookings as occupying rooms tonight" do
      room = create(:room)
      create(:booking, room: room, status: :pending,
                       check_in: Date.current, check_out: Date.current + 2)

      get "/admin"
      expect(response.body).to include("1 / 1")
    end

    it "does not count checked-out bookings as occupying rooms tonight" do
      room = create(:room)
      create(:booking, room: room, status: :checked_out,
                       check_in: Date.current, check_out: Date.current + 2)

      get "/admin"
      expect(response.body).to include("1 / 1")
    end

    it "counts currently staying guests and their rooms" do
      room = create(:room)
      create(:booking, room: room, status: :checked_in,
                       check_in: Date.current, check_out: Date.current + 2)

      get "/admin"
      expect(response.body).to include("Гости сейчас")
      expect(response.body).to include("1 номеров занято")
    end

    it "counts checked-in bookings regardless of their reserved dates" do
      room = create(:room)
      create(:booking, room: room, status: :checked_in,
                       check_in: Date.current + 5, check_out: Date.current + 7)

      get "/admin"
      expect(response.body).to include("1 номеров занято")
    end

    it "counts monthly revenue from accepted payments" do
      booking = create(:booking, :checked_out)
      create(:payment, booking: booking, amount: 4000, paid_at: Time.current)
      create(:payment, booking: booking, amount: 2000, paid_at: Time.current)

      get "/admin"
      expect(response.body).to include("₽6 000")
    end

    it "shows the tariff-based revenue for checked-out bookings" do
      room = create(:room, price_per_night: 1000)
      create(:booking, room: room, status: :checked_out,
                       check_in: Date.current - 5, check_out: Date.current + 1)

      get "/admin"
      expect(response.body).to include("по тарифу ₽6 000")
    end
  end
end
