require "rails_helper"

RSpec.describe "Account", type: :request do
  describe "GET /account" do
    it "shows stays for the phone" do
      user = create(:user, phone: "+7 900 000-00-01", full_name: "Иван Петров")
      stay = create(:stay, :confirmed, user: user)

      get account_path, params: { phone: user.phone }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Иван Петров")
    end

    it "renders an empty state for an unknown phone" do
      get account_path, params: { phone: "+7 900 000-99-99" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /account/find" do
    it "redirects to the account page for the phone" do
      get account_find_path, params: { phone: "+7 900 000-00-02" }
      expect(response).to redirect_to(account_path(phone: "+7 900 000-00-02"))
    end
  end
end
