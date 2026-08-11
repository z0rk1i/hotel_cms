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

    it "returns an empty array for invalid dates" do
      get available_admin_rooms_path(check_in: "not-a-date", check_out: Date.current + 2)
      expect(JSON.parse(response.body)).to eq([])
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
end
