require "rails_helper"

RSpec.describe "Admin stays", type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  describe "GET /admin/stays" do
    it "lists stays" do
      stay = create(:stay)
      get admin_stays_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(stay.user.full_name)
    end

    it "filters by status" do
      confirmed = create(:stay, :confirmed)
      create(:stay, :cancelled)

      get admin_stays_path, params: { status: "confirmed" }
      expect(response.body).to include(confirmed.user.full_name)
    end
  end

  describe "GET /admin/stays/:id" do
    it "shows a stay with user and room info" do
      stay = create(:stay)
      get admin_stay_path(stay)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(stay.room.number)
    end
  end

  describe "POST /admin/stays" do
    it "creates a stay and redirects to it" do
      room = create(:room)
      user = create(:user)
      post admin_stays_path, params: { stay: {
        room_id: room.id, user_id: user.id,
        check_in: Date.current + 1, check_out: Date.current + 3,
        guests_count: 1, status: "pending"
      } }
      expect(response).to redirect_to(admin_stay_path(Stay.last))
      expect(Stay.last.total_price).to eq(room.price_for_stay(Date.current + 1, Date.current + 3).round(2))
    end

    it "re-renders the form on overlap" do
      room = create(:room)
      user = create(:user)
      create(:stay, room: room, check_in: Date.current + 1, check_out: Date.current + 3)
      post admin_stays_path, params: { stay: {
        room_id: room.id, user_id: user.id,
        check_in: Date.current + 2, check_out: Date.current + 4,
        guests_count: 1
      } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "transitions" do
    it "confirms, checks in and checks out a stay" do
      stay = create(:stay)
      patch confirm_admin_stay_path(stay)
      expect(stay.reload.status).to eq("confirmed")
      patch check_in_admin_stay_path(stay)
      expect(stay.reload.status).to eq("checked_in")
      patch check_out_admin_stay_path(stay)
      expect(stay.reload.status).to eq("checked_out")
    end

    it "rejects an illegal transition with an alert" do
      stay = create(:stay)
      patch check_in_admin_stay_path(stay)
      expect(response).to redirect_to(admin_stay_path(stay))
      expect(flash[:alert]).to be_present
      expect(stay.reload.status).to eq("pending")
    end
  end

  describe "payments" do
    it "adds and removes a payment" do
      stay = create(:stay)
      post add_payment_admin_stay_path(stay), params: { method: "cash", amount: 1500 }
      expect(stay.reload.paid_amount).to eq(1500)
      expect(response).to redirect_to(admin_stay_path(stay))

      payment_id = stay.reload.payments.first["id"]
      delete remove_payment_admin_stay_path(stay, payment_id: payment_id)
      expect(stay.reload.paid_amount).to eq(0)
    end

    it "rejects an invalid payment method" do
      stay = create(:stay)
      post add_payment_admin_stay_path(stay), params: { method: "bitcoin", amount: 10 }
      expect(response).to redirect_to(admin_stay_path(stay))
      expect(flash[:alert]).to be_present
    end
  end

  describe "services" do
    it "adds and cancels a service" do
      stay = create(:stay)
      post add_service_admin_stay_path(stay), params: { name: "Завтрак", price: 500, quantity: 2 }
      expect(stay.reload.services_total).to eq(1000)

      service_id = stay.reload.services.first["id"]
      delete cancel_service_admin_stay_path(stay, service_id: service_id)
      expect(stay.reload.services_total).to eq(0)
    end
  end

  describe "DELETE /admin/stays/:id" do
    it "destroys a pending stay" do
      stay = create(:stay)
      delete admin_stay_path(stay)
      expect(response).to redirect_to(admin_stays_path)
      expect(Stay.exists?(stay.id)).to be(false)
    end
  end
end
