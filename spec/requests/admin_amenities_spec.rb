require "rails_helper"

RSpec.describe "Admin amenities", type: :request do
  before { sign_in create(:administrator) }

  describe "GET /admin/amenities" do
    it "lists amenities" do
      amenity = create(:amenity, name: "Wi-Fi")
      get admin_amenities_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Wi-Fi")
      expect(response.body).to include(amenity.icon)
    end
  end

  describe "GET /admin/amenities/new" do
    it "renders the form" do
      get new_admin_amenity_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/amenities" do
    it "creates an amenity" do
      expect do
        post admin_amenities_path, params: { amenity: { name: "Завтрак", icon: "coffee" } }
      end.to change(Amenity, :count).by(1)

      expect(Amenity.last.name).to eq("Завтрак")
      expect(Amenity.last.icon).to eq("coffee")
      expect(response).to redirect_to(admin_amenities_path)
    end

    it "re-renders the form on invalid attributes" do
      post admin_amenities_path, params: { amenity: { name: "", icon: "star" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/amenities/:id/edit" do
    it "renders the edit form with the current name" do
      amenity = create(:amenity, name: "Wi-Fi")
      get edit_admin_amenity_path(amenity)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Wi-Fi")
    end
  end

  describe "PATCH /admin/amenities/:id" do
    it "updates the amenity" do
      amenity = create(:amenity, name: "Старое название")
      patch admin_amenity_path(amenity), params: { amenity: { name: "Новое название" } }
      expect(amenity.reload.name).to eq("Новое название")
      expect(response).to redirect_to(admin_amenities_path)
    end

    it "re-renders the form on invalid attributes" do
      amenity = create(:amenity)
      patch admin_amenity_path(amenity), params: { amenity: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(amenity.reload.name).not_to be_blank
    end
  end

  describe "DELETE /admin/amenities/:id" do
    it "destroys the amenity" do
      amenity = create(:amenity)
      expect do
        delete admin_amenity_path(amenity)
      end.to change(Amenity, :count).by(-1)
      expect(response).to redirect_to(admin_amenities_path)
    end
  end
end
