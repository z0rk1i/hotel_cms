require "rails_helper"

RSpec.describe "Public bookings", type: :request do
  describe "GET /bookings/new" do
    it "renders the public booking form with a preselected room" do
      room = create(:room)
      get new_booking_path(room_id: room.id)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Бронирование номера")
    end
  end

  describe "POST /bookings" do
    it "creates a user, guest and booking, then signs in the user" do
      room = create(:room, price_per_night: 2000)

      expect do
        post bookings_path, params: {
          booking: {
            room_id: room.id,
            check_in: Date.current + 3,
            check_out: Date.current + 5,
            guests_count: 1
          },
          user: {
            full_name: "Иванов Иван",
            email: "ivan@example.com",
            phone: "+7 900 000-00-00",
            password: "password123"
          }
        }
      end.to change(User, :count).by(1).and change(Guest, :count).by(1).and change(Booking, :count).by(1)

      booking = Booking.last
      expect(response).to redirect_to(bookings_path)
      expect(booking.user.email).to eq("ivan@example.com")
      expect(booking.guest.full_name).to eq("Иванов Иван")
      expect(booking.total_price).to eq(4000)
      expect(booking).to be_pending
      follow_redirect!
      expect(response.body).to include("Бронь создана!")
      expect(response.body).to include("Бронь №#{booking.id}")
    end

    it "rejects a booking with an overlapping stay" do
      existing = create(:booking, check_in: Date.current + 3, check_out: Date.current + 5)
      room = existing.room

      expect do
        post bookings_path, params: {
          booking: {
            room_id: room.id,
            check_in: Date.current + 4,
            check_out: Date.current + 6,
            guests_count: 1
          },
          user: {
            full_name: "Петров Пётр",
            email: "petr@example.com",
            phone: "+7 900 111-11-11",
            password: "password123"
          }
        }
      end.not_to change(Booking, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create a user with a duplicate email" do
      user = create(:user, email: "existing@example.com")
      room = create(:room)

      expect do
        post bookings_path, params: {
          booking: {
            room_id: room.id,
            check_in: Date.current + 3,
            check_out: Date.current + 5,
            guests_count: 1
          },
          user: {
            full_name: "Дубликат",
            email: "existing@example.com",
            phone: "+7 900 222-22-22",
            password: "password123"
          }
        }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /bookings/available_rooms" do
    it "returns only rooms free on the given dates" do
      free_room = create(:room)
      taken_room = create(:room)
      create(:booking, room: taken_room, check_in: Date.current + 3, check_out: Date.current + 5)

      get available_rooms_bookings_path, params: {
        check_in: Date.current + 3,
        check_out: Date.current + 5
      }

      json = JSON.parse(response.body)
      expect(json.map { |r| r["id"] }).to include(free_room.id)
      expect(json.map { |r| r["id"] }).not_to include(taken_room.id)
    end
  end

  describe "GET /bookings" do
    it "requires authentication" do
      get bookings_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "lists only the current user's bookings" do
      user = create(:user)
      own_booking = create(:booking, user: user)
      create(:booking, user: create(:user))

      sign_in user
      get bookings_path

      expect(response.body).to include("Бронь №#{own_booking.id}")
    end
  end

  describe "GET /bookings/:id" do
    it "shows booking details to its owner" do
      user = create(:user)
      booking = create(:booking, user: user)

      sign_in user
      get booking_path(booking)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Бронь №#{booking.id}")
    end
  end
end
