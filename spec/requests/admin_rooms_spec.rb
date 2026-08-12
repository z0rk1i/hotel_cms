require 'rails_helper'

RSpec.describe "Admin rooms", type: :request do
  before { sign_in create(:administrator) }

  describe "GET /admin/rooms/available" do
    it "returns available rooms for the date range as JSON" do
      room = create(:room)
      get available_admin_rooms_path(check_in: Date.current + 10, check_out: Date.current + 12)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.first["id"]).to eq(room.id)
      expect(body.first["label"]).to include(room.number)
    end

    it "excludes rooms occupied during the range" do
      room = create(:room)
      create(:booking, room: room, check_in: Date.current + 10, check_out: Date.current + 12)
      get available_admin_rooms_path(check_in: Date.current + 11, check_out: Date.current + 13)
      body = JSON.parse(response.body)
      expect(body.map { |r| r["id"] }).not_to include(room.id)
    end

    it "excludes rooms under maintenance or cleaning" do
      create(:room, status: :maintenance)
      free_room = create(:room)
      get available_admin_rooms_path(check_in: Date.current + 10, check_out: Date.current + 12)
      body = JSON.parse(response.body)
      expect(body.map { |r| r["id"] }).to eq([ free_room.id ])
    end

    it "excludes rooms with an overlapping unavailability window" do
      create(:room, unavailable_from: Date.current + 9, unavailable_until: Date.current + 15)
      free_room = create(:room)
      get available_admin_rooms_path(check_in: Date.current + 10, check_out: Date.current + 12)
      body = JSON.parse(response.body)
      expect(body.map { |r| r["id"] }).to eq([ free_room.id ])
    end

    it "returns 422 for invalid dates" do
      get available_admin_rooms_path(check_in: "not-a-date", check_out: Date.current + 2)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to have_key("error")
    end
  end

  describe "GET /admin/rooms" do
    it "filters by status" do
      create(:room, number: "A", status: :available)
      create(:room, number: "B", status: :occupied)
      get admin_rooms_path(status: "occupied")
      expect(response.body).to include("B")
      expect(response.body).not_to include("A")
    end
  end

  describe "PATCH /admin/rooms/:id/complete_cleaning" do
    it "marks a cleaning room available and logs the change" do
      room = create(:room, status: :cleaning)

      patch complete_cleaning_admin_room_path(room)

      expect(room.reload).to be_available
      expect(room.status_logs.ordered.first.from_status).to eq("cleaning")
      expect(room.status_logs.ordered.first.to_status).to eq("available")
      expect(response).to redirect_to(admin_rooms_path)
    end
  end

  describe "GET /admin/rooms/:id/status_history" do
    it "renders the room status journal" do
      room = create(:room, status: :cleaning)
      patch complete_cleaning_admin_room_path(room)

      get status_history_admin_room_path(room)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("История статусов")
      expect(response.body).to include("Уборка")
      expect(response.body).to include("Свободен")
    end
  end

  describe "DELETE /admin/rooms/:room_id/photo/:photo_id" do
    it "purges a photo of the room" do
      room = create(:room)
      room.photos.attach(io: File.open(Rails.root.join("spec/fixtures/files/pixel.png")), filename: "p.png", content_type: "image/png")
      photo = room.photos.first

      expect do
        delete admin_room_photo_path(room, photo)
      end.to change { room.photos.reload.count }.by(-1)

      expect(response).to redirect_to(edit_admin_room_path(room))
    end
  end

  describe "redirects after successful changes" do
    it "redirects to the previous page after creating" do
      category = create(:room_category)
      get new_admin_room_path, headers: { "HTTP_REFERER" => admin_rooms_path }
      post admin_rooms_path, params: { room: { number: "777", category_id: category.id, floor: 1, capacity: 2, price_per_night: 1000 } }
      expect(response).to redirect_to(admin_rooms_path)
    end

    it "redirects to the previous page after updating" do
      room = create(:room)
      get edit_admin_room_path(room), headers: { "HTTP_REFERER" => admin_rooms_path }
      patch admin_room_path(room), params: { room: { number: "778" } }
      expect(response).to redirect_to(admin_rooms_path)
    end

    it "falls back to the index when there is no previous page" do
      category = create(:room_category)
      post admin_rooms_path, params: { room: { number: "779", category_id: category.id, floor: 1, capacity: 2, price_per_night: 1000 } }
      expect(response).to redirect_to(admin_rooms_path)
    end
  end

  describe "amenities assignment" do
    it "saves amenity_ids when creating a room" do
      category = create(:room_category)
      amenity = create(:amenity)
      post admin_rooms_path, params: {
        room: { number: "101", category_id: category.id, floor: 1, capacity: 2,
                price_per_night: 1000, amenity_ids: [ amenity.id ] }
      }
      expect(Room.last.amenities).to include(amenity)
    end

    it "updates amenity_ids when updating a room" do
      room = create(:room)
      amenity = create(:amenity)
      patch admin_room_path(room), params: { room: { number: room.number, amenity_ids: [ amenity.id ] } }
      expect(room.reload.amenities).to include(amenity)
    end
  end
end
