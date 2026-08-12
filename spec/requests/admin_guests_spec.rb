require 'rails_helper'

RSpec.describe "Admin guests", type: :request do
  before { sign_in create(:administrator) }

  describe "CSV export" do
    it "exports all guests as CSV" do
      guest = create(:guest, full_name: "Иван Иванов", passport_number: "1234567890")
      create(:guest)

      get admin_guests_path(format: :csv)

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to include("text/csv")

      rows = CSV.parse(response.body)
      expect(rows.length).to eq(3)
      expect(rows.first).to include("Имя", "Паспорт")
      expect(rows.map(&:first)).to include("Иван Иванов")
      expect(rows.detect { |r| r[0] == "Иван Иванов" }[3]).to eq("1234567890")
    end

    it "respects the search query" do
      create(:guest, full_name: "Иван Иванов")
      create(:guest, full_name: "Пётр Петров")

      get admin_guests_path(format: :csv, query: "Иван")

      rows = CSV.parse(response.body)
      expect(rows.length).to eq(2)
      expect(rows.last[0]).to eq("Иван Иванов")
    end
  end
end
