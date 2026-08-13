require "rails_helper"

RSpec.describe "Admin dashboard", type: :request do
  let(:admin) { create(:user, :admin) }

  describe "GET /admin" do
    it "redirects anonymous visitors to sign in" do
      get "/admin"
      expect(response).to redirect_to(new_user_session_path)
    end

    it "renders the dashboard for authenticated admins" do
      sign_in admin
      get "/admin"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Дашборд")
    end
  end
end
