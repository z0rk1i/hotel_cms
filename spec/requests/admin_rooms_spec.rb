require "rails_helper"

RSpec.describe "Admin rooms", type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  describe "GET /admin/rooms" do
    it "lists rooms" do
      create(:room, number: "101")
      get admin_rooms_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("101")
    end

    it "filters by status" do
      available = create(:room, number: "101")
      create(:room, number: "102", status: "maintenance")

      get admin_rooms_path, params: { status: "maintenance" }
      expect(response.body).not_to include("101")
      expect(response.body).to include("102")
    end

    it "searches by number" do
      create(:room, number: "777")
      get admin_rooms_path, params: { query: "77" }
      expect(response.body).to include("777")
    end
  end

  describe "POST /admin/rooms" do
    it "creates a room and redirects" do
      post admin_rooms_path, params: { room: {
        number: "103", category: "Стандарт", floor: 1, capacity: 2,
        size_sqm: 18, price_per_night: 2500, weekend_multiplier: 1.2,
        min_nights: 1, status: "available"
      } }
      expect(response).to redirect_to(admin_rooms_path)
      expect(Room.find_by(number: "103")).to be_present
    end

    it "re-renders the form on validation error" do
      post admin_rooms_path, params: { room: { number: "103", capacity: 0 } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /admin/rooms/:id" do
    it "updates the room" do
      room = create(:room, number: "101")
      patch admin_room_path(room), params: { room: { price_per_night: 5000 } }
      expect(response).to redirect_to(admin_rooms_path)
      expect(room.reload.price_per_night).to eq(5000)
    end
  end

  describe "DELETE /admin/rooms/:id" do
    it "destroys an unused room" do
      room = create(:room)
      delete admin_room_path(room)
      expect(response).to redirect_to(admin_rooms_path)
      expect(Room.exists?(room.id)).to be(false)
    end
  end

  describe "PATCH /admin/rooms/:id/complete_cleaning" do
    it "sets the room back to available" do
      room = create(:room, status: "cleaning")
      patch complete_cleaning_admin_room_path(room)
      expect(room.reload.status).to eq("available")
      expect(response).to redirect_to(admin_rooms_path)
    end
  end
end
