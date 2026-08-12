require "rails_helper"

RSpec.describe "Public bookings", type: :request do
  describe "GET /bookings/new" do
    it "renders the public booking form with a preselected room" do
      room = create(:room)
      get new_booking_path(room_id: room.id)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Бронирование номера")
    end

    it "prefills the dates from the query params" do
      room = create(:room)
      get new_booking_path(room_id: room.id, check_in: Date.current + 7, check_out: Date.current + 9)
      expect(response.body).to include((Date.current + 7).to_s)
      expect(response.body).to include((Date.current + 9).to_s)
    end

    it "renders the personal data consent checkbox and policy link" do
      room = create(:room)
      get new_booking_path(room_id: room.id)
      expect(response.body).to include("Я согласен на обработку персональных данных")
      expect(response.body).to include("политике обработки персональных данных")
    end

    it "renders the personal data policy page" do
      get privacy_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Политика обработки персональных данных")
    end
  end

  describe "POST /bookings" do
    it "creates a user, guest and booking, then signs in the user" do
      create(:administrator)
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
          },
          consent_given: "1"
        }
      end.to change(User, :count).by(1).and change(Guest, :count).by(1).and change(Booking, :count).by(1).and change(ConsentLog, :count).by(1).and change(Notification.for_admin, :count).by(1)

      booking = Booking.last
      expect(response).to redirect_to(account_path)
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

    it "copies the user's phone to the guest" do
      room = create(:room)

      post bookings_path, params: {
        booking: {
          room_id: room.id,
          check_in: Date.current + 3,
          check_out: Date.current + 5,
          guests_count: 1
        },
        user: {
          full_name: "С Телефоном",
          email: "phone@example.com",
          phone: "+7 900 333-33-33",
          password: "password123"
        },
        consent_given: "1"
      }

      expect(Booking.last.guest.phone).to eq("+7 900 333-33-33")
    end

    it "rejects a booking without personal data consent" do
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
            full_name: "Без Согласия",
            email: "noconsent@example.com",
            phone: "+7 900 888-88-88",
            password: "password123"
          }
        }
      end.not_to change(Booking, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Необходимо согласие на обработку персональных данных")
    end

    it "does not create a user or guest when the booking fails" do
      existing = create(:booking, check_in: Date.current + 3, check_out: Date.current + 5)
      room = existing.room

      before_post = [ User.count, Guest.count ]
      post bookings_path, params: {
        booking: {
          room_id: room.id,
          check_in: Date.current + 4,
          check_out: Date.current + 6,
          guests_count: 1
        },
        user: {
          full_name: "Без Аккаунта",
          email: "noaccount@example.com",
          phone: "+7 900 444-44-44",
          password: "password123"
        }
      }

      expect([ User.count, Guest.count ]).to eq(before_post)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects a booking with check_in in the past" do
      room = create(:room)

      expect do
        post bookings_path, params: {
          booking: {
            room_id: room.id,
            check_in: Date.current - 1,
            check_out: Date.current + 1,
            guests_count: 1
          },
          user: {
            full_name: "Просрочка",
            email: "overdue@example.com",
            phone: "+7 900 555-55-55",
            password: "password123"
          }
        }
      end.not_to change(Booking, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects a booking over a closed date" do
      room = create(:room)
      create(:closed_date, date: Date.current + 4)

      expect do
        post bookings_path, params: {
          booking: {
            room_id: room.id,
            check_in: Date.current + 3,
            check_out: Date.current + 5,
            guests_count: 1
          },
          user: {
            full_name: "Закрыто",
            email: "closeddate@example.com",
            phone: "+7 900 666-66-66",
            password: "password123"
          }
        }
      end.not_to change(Booking, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("отель закрыт на выбранные даты")
    end

    it "rejects a booking shorter than the period minimum" do
      room = create(:room)
      create(:price_period, starts_on: Date.current + 3, ends_on: Date.current + 9, min_nights: 3)

      expect do
        post bookings_path, params: {
          booking: {
            room_id: room.id,
            check_in: Date.current + 3,
            check_out: Date.current + 5,
            guests_count: 1
          },
          user: {
            full_name: "Коротко",
            email: "shortstay@example.com",
            phone: "+7 900 777-77-77",
            password: "password123"
          }
        }
      end.not_to change(Booking, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("минимальный срок проживания составляет 3 ночи")
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

    it "includes label, price and capacity for each room" do
      room = create(:room, capacity: 3, price_per_night: 2500)
      get available_rooms_bookings_path, params: {
        check_in: Date.current + 3,
        check_out: Date.current + 5
      }
      room_json = JSON.parse(response.body).find { |r| r["id"] == room.id }
      expect(room_json["label"]).to include(room.number)
      expect(room_json["price"]).to eq(2500.0)
      expect(room_json["capacity"]).to eq(3)
    end

    it "does not offer rooms under maintenance or cleaning" do
      maintenance_room = create(:room, status: :maintenance)
      cleaning_room = create(:room, status: :cleaning)
      free_room = create(:room)

      get available_rooms_bookings_path, params: {
        check_in: Date.current + 3,
        check_out: Date.current + 5
      }

      json = JSON.parse(response.body)
      expect(json.map { |r| r["id"] }).to include(free_room.id)
      expect(json.map { |r| r["id"] }).not_to include(maintenance_room.id, cleaning_room.id)
    end

    it "returns 422 when the date range is invalid" do
      get available_rooms_bookings_path, params: {
        check_in: Date.current + 5,
        check_out: Date.current + 3
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to have_key("error")

      get available_rooms_bookings_path, params: {
        check_in: "not-a-date",
        check_out: Date.current + 3
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 with a message when the stay overlaps a closed date" do
      create(:closed_date, date: Date.current + 4)

      get available_rooms_bookings_path, params: {
        check_in: Date.current + 3,
        check_out: Date.current + 5
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("Отель закрыт на выбранные даты")
    end

    it "returns 422 with a message when the stay is shorter than the period minimum" do
      create(:price_period, starts_on: Date.current + 3, ends_on: Date.current + 9, min_nights: 3)

      get available_rooms_bookings_path, params: {
        check_in: Date.current + 3,
        check_out: Date.current + 5
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("Минимальный срок проживания — 3 ночи")
    end
  end

  describe "GET /bookings" do
    it "redirects to the personal account dashboard" do
      user = create(:user)
      sign_in user
      get bookings_path
      expect(response).to redirect_to(account_path)
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

    it "shows the cancel button for a pending booking" do
      user = create(:user)
      booking = create(:booking, :pending, user: user)

      sign_in user
      get booking_path(booking)

      expect(response.body).to include("Отменить бронь")
    end
  end

  describe "POST /bookings/:id/cancel" do
    it "lets the owner cancel a pending booking" do
      user = create(:user)
      booking = create(:booking, :pending, user: user)
      sign_in user

      expect { post cancel_booking_path(booking) }.to change { booking.reload.status }
        .from("pending").to("cancelled")

      expect(response).to redirect_to(account_path)
      expect(flash[:notice]).to eq("Бронь отменена.")
    end

    it "lets the owner cancel a confirmed booking" do
      user = create(:user)
      booking = create(:booking, :confirmed, user: user)
      sign_in user

      post cancel_booking_path(booking)

      expect(booking.reload).to be_cancelled
    end

    it "does not cancel a checked-in booking" do
      user = create(:user)
      booking = create(:booking, :checked_in, user: user)
      sign_in user

      post cancel_booking_path(booking)

      expect(booking.reload).to be_checked_in
      expect(flash[:alert]).to be_present
    end

    it "does not allow cancelling someone else's booking" do
      booking = create(:booking, user: create(:user))
      sign_in create(:user)

      post cancel_booking_path(booking)

      expect(response).to have_http_status(:not_found)
      expect(booking.reload).to be_pending
    end

    it "requires authentication" do
      booking = create(:booking)
      post cancel_booking_path(booking)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
