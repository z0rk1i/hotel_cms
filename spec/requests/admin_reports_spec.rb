require "rails_helper"

RSpec.describe "Admin reports", type: :request do
  before { sign_in create(:administrator) }

  let(:from) { Date.current + 1 }
  let(:to) { from + 3 }

  def money_string(amount)
    ActionController::Base.helpers.number_to_currency(amount, unit: "₽", separator: ",", delimiter: " ", precision: 0)
  end

  describe "GET /admin/reports" do
    it "renders the period report with revenue and occupancy" do
      room = create(:room)
      booking = create(:booking, :confirmed, room: room, check_in: from, check_out: from + 2)
      create(:payment, booking: booking, amount: 2500, paid_at: from.beginning_of_day + 1.hour)

      get admin_reports_path(from: from, to: to)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Отчёты")
      expect(response.body).to include("Загрузка по категориям номеров")
      expect(response.body).to include("Ночная загрузка")
      frozen_plan = BookingNightlyPrice.where(booking: booking).sum(:amount)
      expect(frozen_plan).to eq(booking.reload.total_price)
      expect(response.body).to include(money_string(booking.total_price))
      expect(response.body).to include("₽2 500")
    end

    it "defaults to the current month when params are absent" do
      get admin_reports_path
      expect(response).to have_http_status(:ok)
    end

    it "falls back to the current month for malformed dates" do
      get admin_reports_path(from: "not-a-date", to: "also-bad")
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/reports/export" do
    it "returns a CSV with nightly rows" do
      room = create(:room)
      create(:booking, :confirmed, room: room, check_in: from, check_out: from + 2)

      get admin_reports_export_path(from: from, to: to)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/csv")
      rows = CSV.parse(response.body)
      expect(rows.first).to eq([ "Дата", "План, ₽", "Факт, ₽", "Занято номеров", "Всего номеров", "Загрузка, %" ])
      expect(rows.size).to eq(5)
    end
  end

  describe "dashboard link" do
    it "links to the current-month report" do
      get admin_root_path
      expect(response.body).to include("Отчёт за этот месяц")
      expect(response.body).to include("from=2026-08-01")
      expect(response.body).to include("to=2026-08-31")
    end
  end
end
