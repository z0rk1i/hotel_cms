require "rails_helper"

RSpec.describe "Public room pages", type: :request do
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
      approved = create(:review, :approved, reviewable: room, body: "Отличный номер")
      create(:review, reviewable: room, body: "Ожидает модерации")

      get room_path(room)
      expect(response.body).to include("Отличный номер")
      expect(response.body).not_to include("Ожидает модерации")
      expect(response.body).to include(approved.rating.to_s)
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
      sign_in user

      expect do
        post reviews_path, params: {
          review: { reviewable_type: "Service", reviewable_id: service.id, rating: 4, body: "Хорошая услуга" }
        }
      end.to change(Review, :count).by(1)

      expect(Review.last.reviewable).to eq(service)
      expect(response).to redirect_to(service_path(service))
    end

    it "rejects a review without rating or body" do
      user = create(:user)
      room = create(:room)
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
