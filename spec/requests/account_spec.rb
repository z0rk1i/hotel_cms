require "rails_helper"

RSpec.describe "Account dashboard", type: :request do
  describe "GET /account" do
    it "requires authentication" do
      get account_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows bookings and service orders for the current user" do
      user = create(:user)
      booking = create(:booking, user: user)
      order = create(:service_order, user: user)

      sign_in user
      get account_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Личный кабинет")
      expect(response.body).to include("Бронь №#{booking.id}")
      expect(response.body).to include(order.service.name)
    end

    it "does not show other users' bookings or orders" do
      create(:booking, user: create(:user))
      create(:service_order, user: create(:user))

      sign_in create(:user)
      get account_path

      expect(response).to have_http_status(:ok)
      expect(response.body.scan("Бронь №").size).to be < 2
    end
  end
end
