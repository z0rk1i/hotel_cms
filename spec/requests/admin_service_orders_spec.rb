require "rails_helper"

RSpec.describe "Admin service orders", type: :request do
  let(:admin) { create(:administrator) }

  before { sign_in admin }

  describe "GET /admin/service_orders" do
    it "lists service orders with guest, service and status" do
      order = create(:service_order)

      get admin_service_orders_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(order.service.name)
    end

    it "filters by status" do
      confirmed = create(:service_order, :confirmed)
      create(:service_order)

      get admin_service_orders_path(status: "confirmed")
      expect(response.body).to include(confirmed.service.name)
    end
  end

  describe "PATCH /admin/service_orders/:id/confirm" do
    it "confirms a pending order and notifies the user" do
      order = create(:service_order)

      expect { patch confirm_admin_service_order_path(order) }
        .to change(order.user.notifications, :count).by(1)
      expect(order.reload).to be_confirmed
      expect(response).to redirect_to(admin_service_orders_path)
    end
  end

  describe "PATCH /admin/service_orders/:id/cancel" do
    it "cancels a pending order and notifies the user" do
      order = create(:service_order)

      expect { patch cancel_admin_service_order_path(order) }
        .to change(order.user.notifications, :count).by(1)
      expect(order.reload).to be_cancelled
    end
  end

  describe "authentication" do
    it "requires an administrator" do
      sign_out admin
      get admin_service_orders_path
      expect(response).to redirect_to(new_administrator_session_path)
    end
  end
end
