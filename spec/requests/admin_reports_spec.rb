require "rails_helper"

RSpec.describe "Admin reports", type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  describe "GET /admin/reports" do
    it "renders the monthly report" do
      get admin_reports_path, params: { from: Date.current.beginning_of_month, to: Date.current.end_of_month }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Отчёты")
    end

    it "exports CSV" do
      get admin_reports_path(format: :csv), params: { from: Date.current.beginning_of_month, to: Date.current.end_of_month }
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to include("text/csv")
      expect(response.body).to include("Дата")
      expect(response.body).to include("По тарифу (план), ₽")
    end
  end
end
