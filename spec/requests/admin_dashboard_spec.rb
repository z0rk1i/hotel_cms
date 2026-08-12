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
      create(:booking, room: room, check_in: Date.current, check_out: Date.current + 2)

      get "/admin"
      expect(response.body).to include("0 / 1")
    end

    it "counts currently staying guests and their rooms" do
      room = create(:room)
      create(:booking, room: room, status: :checked_in,
                       check_in: Date.current, check_out: Date.current + 2)

      get "/admin"
      expect(response.body).to include("Гости сейчас")
      expect(response.body).to include("1 номеров занято")
    end

    it "ignores checked-in bookings whose dates do not include today" do
      room = create(:room)
      create(:booking, room: room, status: :checked_in,
                       check_in: Date.current + 5, check_out: Date.current + 7)

      get "/admin"
      expect(response.body).to include("0 номеров занято")
      expect(response.body).to include("Сейчас никто не заселён")
    end

    it "counts monthly revenue by check_out date" do
      room = create(:room, price_per_night: 1000)
      create(:booking, room: room, status: :checked_out,
                       check_in: Date.current - 5, check_out: Date.current + 1)

      get "/admin"
      expect(response.body).to include("₽6 000")
    end
  end
end
