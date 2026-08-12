require "rails_helper"

RSpec.describe "Admin price periods", type: :request do
  before { sign_in create(:administrator) }

  describe "GET /admin/price_periods" do
    it "lists price periods" do
      create(:price_period, name: "Высокий сезон")
      get admin_price_periods_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Высокий сезон")
    end
  end

  describe "GET /admin/price_periods/new" do
    it "renders the form" do
      get new_admin_price_period_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/price_periods" do
    it "creates a price period" do
      expect do
        post admin_price_periods_path,
             params: { price_period: { name: "Высокий сезон", starts_on: Date.current, ends_on: Date.current + 30, multiplier: 1.3 } }
      end.to change(PricePeriod, :count).by(1)

      expect(PricePeriod.last.name).to eq("Высокий сезон")
      expect(PricePeriod.last.multiplier.to_f).to eq(1.3)
      expect(response).to redirect_to(admin_price_periods_path)
    end

    it "rejects overlapping periods" do
      create(:price_period, starts_on: Date.current, ends_on: Date.current + 30)
      expect do
        post admin_price_periods_path,
             params: { price_period: { name: "Другой", starts_on: Date.current + 10, ends_on: Date.current + 20, multiplier: 1.1 } }
      end.not_to change(PricePeriod, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/price_periods/:id/edit" do
    it "renders the edit form with the current name" do
      period = create(:price_period, name: "Высокий сезон")
      get edit_admin_price_period_path(period)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Высокий сезон")
    end
  end

  describe "PATCH /admin/price_periods/:id" do
    it "updates the price period" do
      period = create(:price_period)
      patch admin_price_period_path(period), params: { price_period: { multiplier: 1.5 } }
      expect(period.reload.multiplier.to_f).to eq(1.5)
      expect(response).to redirect_to(admin_price_periods_path)
    end

    it "re-renders the form on invalid attributes" do
      period = create(:price_period)
      patch admin_price_period_path(period), params: { price_period: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(period.reload.name).not_to be_blank
    end
  end

  describe "DELETE /admin/price_periods/:id" do
    it "destroys the price period" do
      period = create(:price_period)
      expect do
        delete admin_price_period_path(period)
      end.to change(PricePeriod, :count).by(-1)
      expect(response).to redirect_to(admin_price_periods_path)
    end
  end
end
