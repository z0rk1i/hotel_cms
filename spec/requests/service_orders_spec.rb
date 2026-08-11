require "rails_helper"

RSpec.describe "Service orders", type: :request do
  describe "GET /service_orders/new" do
    it "requires authentication" do
      get new_service_order_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "preselects the service from the query param" do
      service = create(:service)
      sign_in create(:user)

      get new_service_order_path(service_id: service.id)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Заказ услуги")
    end
  end

  describe "POST /service_orders" do
    it "creates a service order for the current user and redirects to account" do
      service = create(:service, price: 1000)
      user = create(:user)
      sign_in user

      expect do
        post service_orders_path, params: {
          service_order: {
            service_id: service.id,
            service_date: Date.current + 5,
            quantity: 2,
            notes: "Отдельный вход"
          }
        }
      end.to change(ServiceOrder, :count).by(1)

      order = ServiceOrder.last
      expect(order.user).to eq(user)
      expect(order.total_price).to eq(2000)
      expect(order).to be_pending
      expect(response).to redirect_to(account_path)
    end

    it "rejects an order without a service or date" do
      sign_in create(:user)

      expect do
        post service_orders_path, params: { service_order: { quantity: 1 } }
      end.not_to change(ServiceOrder, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /service_orders/:id/cancel" do
    it "lets the owner cancel a pending order" do
      user = create(:user)
      order = create(:service_order, user: user)
      sign_in user

      post cancel_service_order_path(order)
      expect(order.reload).to be_cancelled
      expect(response).to redirect_to(account_path)
    end

    it "does not allow cancelling someone else's order" do
      order = create(:service_order, user: create(:user))
      sign_in create(:user)

      post cancel_service_order_path(order)
      expect(response).to have_http_status(:not_found)
      expect(order.reload).to be_pending
    end
  end
end
