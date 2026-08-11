require 'rails_helper'

RSpec.describe "Authentication", type: :request do
  describe "admin area" do
    it "redirects anonymous users to sign in" do
      get "/admin"
      expect(response).to redirect_to("/admin/sign_in")
    end

    it "redirects anonymous users from protected pages" do
      get "/admin/rooms"
      expect(response).to redirect_to("/admin/sign_in")
    end

    it "allows authenticated administrators to access the dashboard" do
      sign_in create(:administrator)
      get "/admin"
      expect(response).to have_http_status(:ok)
    end

    it "redirects an administrator to the dashboard after signing in" do
      admin = create(:administrator)
      post "/admin/sign_in", params: { administrator: { email: admin.email, password: admin.password } }
      expect(response).to redirect_to(admin_root_path)
    end

    it "allows authenticated administrators to list rooms" do
      sign_in create(:administrator)
      get "/admin/rooms"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "public site" do
    it "renders the homepage" do
      get "/"
      expect(response).to have_http_status(:ok)
    end

    it "renders a page by slug" do
      page = create(:page, slug: "about", title: "О гостинице")
      get "/pages/#{page.slug}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("О гостинице")
    end

    it "returns 404 for an unknown page" do
      get "/pages/nonexistent"
      expect(response).to have_http_status(:not_found)
    end
  end
end
