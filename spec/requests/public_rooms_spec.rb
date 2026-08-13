require "rails_helper"

RSpec.describe "Public room pages", type: :request do
  describe "GET /" do
    it "groups rooms under their categories" do
      standard = create(:room_category, name: "Стандарт")
      luxury = create(:room_category, name: "Люкс")
      create(:room, number: "101", category: standard)
      create(:room, number: "201", category: luxury)

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Стандарт")
      expect(response.body).to include("Люкс")
      expect(response.body).to include("Номер 101")
      expect(response.body).to include("Номер 201")
    end

    it "renders amenity badges on room cards" do
      room = create(:room)
      room.amenities << create(:amenity, name: "Балкон")
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Балкон")
    end

    it "filters rooms by selected amenities" do
      balcony = create(:amenity, name: "Балкон")
      wifi = create(:amenity, name: "Wi-Fi")
      with_balcony = create(:room, number: "101")
      with_balcony.amenities << balcony
      with_wifi = create(:room, number: "102")
      with_wifi.amenities << wifi

      get root_path(amenities: [ balcony.id ])
      expect(response.body).to include("Номер 101")
      expect(response.body).not_to include("Номер 102")
    end

    it "matches rooms that have all selected amenities" do
      balcony = create(:amenity, name: "Балкон")
      wifi = create(:amenity, name: "Wi-Fi")
      full_room = create(:room, number: "101")
      full_room.amenities << [ balcony, wifi ]
      partial_room = create(:room, number: "102")
      partial_room.amenities << wifi

      get root_path(amenities: [ balcony.id, wifi.id ])
      expect(response.body).to include("Номер 101")
      expect(response.body).not_to include("Номер 102")
    end

    it "renders category and sorting controls" do
      create(:room)
      get root_path
      expect(response.body).to include("Все типы")
      expect(response.body).to include("по цене ↑")
      expect(response.body).to include("по цене ↓")
    end

    it "filters rooms by category" do
      standard = create(:room_category, name: "Стандарт")
      luxury = create(:room_category, name: "Люкс")
      create(:room, number: "101", category: standard)
      create(:room, number: "201", category: luxury)

      get root_path(category_id: standard.id)

      expect(response.body).to include("Номер 101")
      expect(response.body).not_to include("Номер 201")
    end

    it "sorts rooms by price when requested" do
      category = create(:room_category)
      create(:room, number: "101", category: category, price_per_night: 1500)
      create(:room, number: "201", category: category, price_per_night: 9000)

      get root_path(sort: "price_asc")

      expect(response.body.index("Номер 101")).to be < response.body.index("Номер 201")
    end

    it "reorders category sections by room price when sorting" do
      standard = create(:room_category, name: "Стандарт")
      luxury = create(:room_category, name: "Люкс")
      create(:room, number: "101", category: standard, price_per_night: 1500)
      create(:room, number: "201", category: luxury, price_per_night: 9000)

      get root_path(sort: "price_asc")
      expect(response.body.index("Номер 101")).to be < response.body.index("Номер 201")

      get root_path(sort: "price_desc")
      expect(response.body.index("Номер 201")).to be < response.body.index("Номер 101")
    end

    it "anchors filter and sort links to the rooms section" do
      create(:room, number: "101")
      get root_path(sort: "price_asc")

      expect(response.body).to include('href="/?sort=price_asc#rooms"')
      expect(response.body).to include('href="/?sort=price_desc#rooms"')
      expect(response.body).to include('href="/#rooms"')
    end

    it "keeps dates and sort when toggling an amenity filter" do
      balcony = create(:amenity, name: "Балкон")
      wifi = create(:amenity, name: "Wi-Fi")
      room = create(:room, number: "101")
      room.amenities << [ balcony, wifi ]
      from = Date.current + 3
      to = Date.current + 5

      get root_path(amenities: [ wifi.id ], check_in: from, check_out: to, sort: "price_asc")

      balcony_href = response.body[%r{<a[^>]*href="([^"]*)"[^>]*>[^<]*Балкон}, 1]
      expect(balcony_href).to include("check_in=#{from}")
      expect(balcony_href).to include("check_out=#{to}")
      expect(balcony_href).to include("sort=price_asc")
      expect(balcony_href).to include("#rooms")
    end
  end

  describe "GET / with availability search" do
    it "hides rooms already booked for the selected dates" do
      free_room = create(:room, number: "101")
      taken_room = create(:room, number: "102")
      create(:booking, :confirmed, room: taken_room,
             check_in: Date.current + 3, check_out: Date.current + 5)

      get root_path(check_in: Date.current + 3, check_out: Date.current + 5)

      expect(response.body).to include("Номер 101")
      expect(response.body).not_to include("Номер 102")
    end

    it "hides rooms under maintenance" do
      maintenance_room = create(:room, number: "101", status: :maintenance)
      free_room = create(:room, number: "102")

      get root_path(check_in: Date.current + 3, check_out: Date.current + 5)

      expect(response.body).to include("Номер 102")
      expect(response.body).not_to include("Номер 101")
    end

    it "filters rooms by guest capacity" do
      small_room = create(:room, number: "101", capacity: 1)
      big_room = create(:room, number: "102", capacity: 3)

      get root_path(check_in: Date.current + 3, check_out: Date.current + 5, guests_count: 3)

      expect(response.body).to include("Номер 102")
      expect(response.body).not_to include("Номер 101")
    end

    it "shows the search banner and an empty state when nothing is free" do
      create(:room, number: "101")
      create(:booking, :confirmed, room: Room.find_by(number: "101"),
             check_in: Date.current + 3, check_out: Date.current + 5)

      get root_path(check_in: Date.current + 3, check_out: Date.current + 5)

      expect(response.body).to include("Свободные номера")
      expect(response.body).to include("На выбранные даты свободных номеров нет")
    end

    it "ignores an invalid date range and shows all rooms" do
      create(:room, number: "101")
      get root_path(check_in: Date.current + 5, check_out: Date.current + 3)
      expect(response.body).to include("Номер 101")
    end
  end

  describe "GET /rooms/:id" do
    it "renders the room details page" do
      room = create(:room, description: "Просторный номер с видом на горы")
      get room_path(room)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Номер #{room.number}")
      expect(response.body).to include(room.description)
      expect(response.body).to include(room.category.name)
    end

    it "shows approved reviews and hides pending ones" do
      room = create(:room)
      approved_user = create(:user)
      give_user_a_stay!(approved_user, room)
      pending_user = create(:user)
      give_user_a_stay!(pending_user, room)
      approved = create(:review, :approved, reviewable: room, user: approved_user, body: "Отличный номер")
      create(:review, reviewable: room, user: pending_user, body: "Ожидает модерации")

      get room_path(room)
      expect(response.body).to include("Отличный номер")
      expect(response.body).not_to include("Ожидает модерации")
      expect(response.body).to include(approved.rating.to_s)
    end

    it "shows the room amenities as badges" do
      room = create(:room)
      room.amenities << create(:amenity, name: "Кондиционер")
      get room_path(room)
      expect(response.body).to include("Кондиционер")
    end

    it "renders the availability widget with prefilled dates" do
      room = create(:room)
      get room_path(room)
      expect(response.body).to include("Проверить доступность")
      expect(response.body).to include("data-room-availability-room-id-value=\"#{room.id}\"")
      expect(response.body).to include((Date.current + 1).to_s)
    end

    it "shows the next free dates for a free room" do
      room = create(:room)
      get room_path(room)
      expect(response.body).to include("Ближайшие свободные даты")
      expect(response.body).to include(I18n.l(Date.current + 59, format: :long))
    end

    it "returns 404 for an unknown room" do
      get room_path(9999)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /services/:id" do
    it "renders the service details page" do
      service = create(:service, description: "Шведский стол каждое утро")
      get service_path(service)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(service.name)
      expect(response.body).to include(service.description)
    end
  end

  describe "POST /reviews" do
    it "requires authentication" do
      post reviews_path, params: { review: { rating: 5, body: "Отзыв" } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "creates a pending review for a room and redirects back" do
      user = create(:user)
      room = create(:room)
      give_user_a_stay!(user, room)
      sign_in user

      expect do
        post reviews_path, params: {
          review: { reviewable_type: "Room", reviewable_id: room.id, rating: 5, body: "Всё понравилось" }
        }
      end.to change(Review, :count).by(1)

      review = Review.last
      expect(review.user).to eq(user)
      expect(review.reviewable).to eq(room)
      expect(review).to be_pending
      expect(response).to redirect_to(room_path(room))
    end

    it "creates a pending review for a service" do
      user = create(:user)
      service = create(:service)
      give_user_a_stay!(user, service)
      sign_in user

      expect do
        post reviews_path, params: {
          review: { reviewable_type: "Service", reviewable_id: service.id, rating: 4, body: "Хорошая услуга" }
        }
      end.to change(Review, :count).by(1)

      expect(Review.last.reviewable).to eq(service)
      expect(response).to redirect_to(service_path(service))
    end

    it "rejects a review without a completed stay" do
      user = create(:user)
      room = create(:room)
      sign_in user

      expect do
        post reviews_path, params: {
          review: { reviewable_type: "Room", reviewable_id: room.id, rating: 5, body: "Без проживания" }
        }
      end.not_to change(Review, :count)

      expect(response).to redirect_to(room_path(room, anchor: "reviews"))
    end

    it "rejects a review without rating or body" do
      user = create(:user)
      room = create(:room)
      give_user_a_stay!(user, room)
      sign_in user

      expect do
        post reviews_path, params: {
          review: { reviewable_type: "Room", reviewable_id: room.id, body: "" }
        }
      end.not_to change(Review, :count)

      expect(response).to redirect_to(room_path(room, anchor: "reviews"))
    end
  end
end
