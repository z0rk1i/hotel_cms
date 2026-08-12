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
      expect(rows.first).to include("Имя", "Паспорт", "VIP", "Предпочтения")
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

    it "exports VIP and preferences columns" do
      create(:guest, full_name: "VIP-гость", is_vip: true, preferences: "Шоколад")

      get admin_guests_path(format: :csv)

      row = CSV.parse(response.body).detect { |r| r[0] == "VIP-гость" }
      expect(row[6]).to eq("да")
      expect(row[7]).to eq("Шоколад")
    end
  end

  describe "creation" do
    it "persists VIP flag and preferences" do
      post admin_guests_path, params: { guest: { full_name: "Иван Иванов", is_vip: "1", preferences: "Мини-бар", notes: "Встреча в 12:00" } }

      guest = Guest.last
      expect(guest.is_vip).to be(true)
      expect(guest.preferences).to eq("Мини-бар")
      expect(guest.notes).to eq("Встреча в 12:00")
    end
  end

  describe "guest card" do
    it "shows the card with history, revenue and paid amounts" do
      guest = create(:guest, full_name: "Иван Иванов")
      booking = create(:booking, :checked_out, guest: guest)
      create(:payment, booking: booking, amount: 2500)

      get admin_guest_path(guest)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("История броней", "Сумма за всё время", "Возможные дубли")
      expect(response.body).to include("₽2 500")
    end

    it "links bookings to the whole history" do
      guest = create(:guest)
      booking = create(:booking, :confirmed, guest: guest)

      get admin_guest_path(guest)

      expect(response.body).to include("№#{booking.id}")
    end
  end

  describe "merging duplicates" do
    it "merges the duplicate into the shown guest" do
      guest = create(:guest, full_name: "Иван Иванов", email: nil, phone: "79990000000", passport_number: nil)
      duplicate = create(:guest, full_name: "Иван Игнатьев", email: nil, phone: "79990000000", passport_number: nil)
      booking = create(:booking, guest: duplicate)

      post merge_admin_guest_path(guest), params: { duplicate_id: duplicate.id }

      expect(response).to redirect_to(admin_guest_path(guest))
      expect(booking.reload.guest_id).to eq(guest.id)
      expect(Guest.exists?(duplicate.id)).to be(false)
    end

    it "does not merge a guest into itself" do
      guest = create(:guest)

      post merge_admin_guest_path(guest), params: { duplicate_id: guest.id }

      expect(response).to redirect_to(admin_guest_path(guest))
      expect(Guest.exists?(guest.id)).to be(true)
    end
  end
end
