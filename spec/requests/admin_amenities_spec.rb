require "rails_helper"

RSpec.describe "Admin amenities", type: :request do
  before { sign_in create(:administrator) }

  it_behaves_like "admin CRUD resource" do
    let(:model_class) { Amenity }
    let(:collection_path) { admin_amenities_path }
    let(:new_form_path) { new_admin_amenity_path }
    let(:initial_title) { "Wi-Fi" }
    let(:record) { create(:amenity, name: initial_title) }
    let(:edit_member_path) { edit_admin_amenity_path(record) }
    let(:member_path) { admin_amenity_path(record) }
    let(:listed_title) { initial_title }
    let(:valid_attrs) { { name: "Завтрак", icon: "coffee" } }
    let(:invalid_attrs) { { name: "" } }
    let(:update_attrs) { { name: "Новое название" } }
  end
end
