require "rails_helper"

RSpec.describe "Authentication", type: :request do
  describe "GET /admin/users/sign_in" do
    it "renders the login form" do
      get new_user_session_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Вход в панель управления")
    end
  end

  describe "POST /admin/users/sign_in" do
    it "signs an admin in and redirects to the dashboard" do
      admin = create(:user, :admin, email: "admin@example.com", password: "password123")
      post new_user_session_path, email: admin.email, password: "password123"
      expect(response).to redirect_to(admin_root_path)
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end

    it "signs a guest in but keeps them on the public site" do
      guest = create(:user, email: "guest@example.com", password: "password123")
      post new_user_session_path, email: guest.email, password: "password123"
      expect(response).to redirect_to(root_path)
    end

    it "rejects a wrong password" do
      admin = create(:user, :admin, email: "admin@example.com", password: "password123")
      post new_user_session_path, email: admin.email, password: "wrong"
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "DELETE /admin/users/sign_out" do
    it "signs the user out" do
      admin = create(:user, :admin)
      sign_in admin
      delete destroy_user_session_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
