require "rails_helper"

RSpec.describe "Admin price periods", type: :request do
  before { sign_in create(:administrator) }

  it_behaves_like "admin CRUD resource" do
    let(:model_class) { PricePeriod }
    let(:collection_path) { admin_price_periods_path }
    let(:new_form_path) { new_admin_price_period_path }
    let(:initial_title) { "Высокий сезон" }
    let(:record) { create(:price_period, name: initial_title) }
    let(:edit_member_path) { edit_admin_price_period_path(record) }
    let(:member_path) { admin_price_period_path(record) }
    let(:listed_title) { initial_title }
    let(:valid_attrs) { { name: "Высокий сезон", starts_on: Date.current, ends_on: Date.current + 30, multiplier: 1.3 } }
    let(:invalid_attrs) { { name: "" } }
    let(:update_attrs) { { multiplier: 1.5 } }
  end

  describe "POST /admin/price_periods" do
    it "rejects overlapping periods" do
      create(:price_period, starts_on: Date.current, ends_on: Date.current + 30)
      expect do
        post admin_price_periods_path,
             params: { price_period: { name: "Другой", starts_on: Date.current + 10, ends_on: Date.current + 20, multiplier: 1.1 } }
      end.not_to change(PricePeriod, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
