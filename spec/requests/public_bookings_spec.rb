require "rails_helper"

RSpec.describe "Public bookings", type: :request do
  describe "GET /bookings/new" do
    it "renders the booking form" do
      room = create(:room)
      get new_booking_path(room_id: room.id)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Бронирование")
    end
  end

  describe "GET /bookings/available_rooms" do
    it "returns only rooms free on the requested dates" do
      free = create(:room, number: "101")
      busy = create(:room, number: "102")
      create(:stay, :confirmed, room: busy, check_in: Date.current + 1, check_out: Date.current + 3)

      get bookings_available_rooms_path, params: { check_in: Date.current + 1, check_out: Date.current + 2 }
      expect(response).to have_http_status(:ok)
      data = response.parsed_body
      expect(data.map { |r| r["number"] }).to eq([ "101" ])
    end

    it "handles invalid dates" do
      get bookings_available_rooms_path, params: { check_in: "abc", check_out: "def" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to be_present
    end
  end

  describe "POST /bookings" do
    it "creates a guest and a pending stay" do
      room = create(:room, number: "101")
      expect do
        post bookings_path, params: {
          room_id: room.id,
          check_in: Date.current + 5, check_out: Date.current + 7,
          guests_count: 1,
          full_name: "Иван Петров", phone: "+7 900 123-45-67", email: "ivan@example.org",
          consent: "1"
        }
      end.to change(Stay, :count).by(1).and change(User, :count).by(1)

      expect(response).to redirect_to(account_path(phone: "+7 900 123-45-67"))
      expect(flash[:notice]).to include("Заявка принята")
      user = User.guests.find_by(phone: "+7 900 123-45-67")
      expect(user).to have_consent
    end

    it "reuses an existing guest by phone" do
      user = create(:user, phone: "+7 900 111-22-33", email: "existing@example.org")
      room = create(:room)

      expect do
        post bookings_path, params: {
          room_id: room.id,
          check_in: Date.current + 5, check_out: Date.current + 7,
          guests_count: 1,
          full_name: user.full_name, phone: user.phone, email: user.email,
          consent: "1"
        }
      end.to change(User, :count).by(0)
    end

    it "rejects booking without consent" do
      room = create(:room)
      post bookings_path, params: {
        room_id: room.id,
        check_in: Date.current + 5, check_out: Date.current + 7,
        guests_count: 1,
        full_name: "Иван", phone: "+7 900 222-33-44"
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects an already occupied room" do
      room = create(:room)
      create(:stay, :confirmed, room: room, check_in: Date.current + 5, check_out: Date.current + 7)

      post bookings_path, params: {
        room_id: room.id,
        check_in: Date.current + 5, check_out: Date.current + 7,
        guests_count: 1,
        full_name: "Иван", phone: "+7 900 333-44-55",
        consent: "1"
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Номер уже занят")
    end
  end
end
