require "rails_helper"

RSpec.describe "Public rooms", type: :request do
  describe "GET /" do
    it "lists rooms grouped by category" do
      room = create(:room, number: "101", category: "Стандарт")
      get "/"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("101")
      expect(response.body).to include("Стандарт")
    end

    it "filters rooms by available dates" do
      free = create(:room, number: "101")
      busy = create(:room, number: "102")
      create(:stay, :confirmed, room: busy, check_in: Date.current + 1, check_out: Date.current + 3)

      get "/", params: { check_in: Date.current + 1, check_out: Date.current + 2 }
      expect(response.body).to include("101")
      expect(response.body).not_to include("102")
    end
  end

  describe "GET /rooms/:id" do
    it "shows the room with its next free window" do
      room = create(:room, number: "101")
      get room_path(room)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("101")
    end
  end

  describe "GET /gallery" do
    it "renders the gallery" do
      create(:room, number: "101")
      get gallery_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Галерея")
    end
  end
end
