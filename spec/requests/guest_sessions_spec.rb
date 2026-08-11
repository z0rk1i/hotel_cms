require "rails_helper"

RSpec.describe "Guest authentication", type: :request do
  describe "POST /users/sign_in" do
    it "redirects the guest to their personal account" do
      user = create(:user)
      post user_session_path, params: { user: { email: user.email, password: user.password } }
      expect(response).to redirect_to(bookings_path)
    end
  end

  describe "GET /users/sign_in" do
    it "redirects an already signed-in guest to their personal account" do
      user = create(:user)
      sign_in user
      get new_user_session_path
      expect(response).to redirect_to(bookings_path)
    end
  end
end
