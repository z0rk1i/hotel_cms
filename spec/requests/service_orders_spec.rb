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

    it "shows an empty state when the user has no active booking" do
      sign_in create(:user)

      get new_service_order_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("доступен только при активной брони")
      expect(response.body).not_to include("Выберите бронь")
    end

    it "lists active bookings for selection" do
      user = create(:user)
      booking = create(:booking, :confirmed, user: user, check_in: Date.current + 1, check_out: Date.current + 5)
      create(:booking, :pending, user: user, check_in: Date.current + 1, check_out: Date.current + 5)
      sign_in user

      get new_service_order_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(booking.booking_option_label)
    end
  end

  describe "POST /service_orders" do
    it "creates a service order for the current user with an active booking and redirects to account" do
      service = create(:service, price: 1000)
      user = create(:user)
      booking = create(:booking, :confirmed, user: user, check_in: Date.current + 1, check_out: Date.current + 5)
      sign_in user

      expect do
        post service_orders_path, params: {
          service_order: {
            booking_id: booking.id,
            service_id: service.id,
            service_date: Date.current + 3,
            quantity: 2,
            notes: "Отдельный вход"
          }
        }
      end.to change(ServiceOrder, :count).by(1)

      order = ServiceOrder.last
      expect(order.user).to eq(user)
      expect(order.booking).to eq(booking)
      expect(order.total_price).to eq(2000)
      expect(order).to be_pending
      expect(response).to redirect_to(account_path)
    end

    it "rejects an order without an active booking" do
      service = create(:service)
      sign_in create(:user)

      expect do
        post service_orders_path, params: {
          service_order: { service_id: service.id, service_date: Date.current + 3, quantity: 1 }
        }
      end.not_to change(ServiceOrder, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects an order tied to someone else's booking" do
      service = create(:service)
      user = create(:user)
      other_booking = create(:booking, :confirmed, user: create(:user))
      sign_in user

      expect do
        post service_orders_path, params: {
          service_order: {
            booking_id: other_booking.id,
            service_id: service.id,
            service_date: Date.current + 3,
            quantity: 1
          }
        }
      end.not_to change(ServiceOrder, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects an order whose date is outside the booking period" do
      service = create(:service)
      user = create(:user)
      booking = create(:booking, :confirmed, user: user, check_in: Date.current + 1, check_out: Date.current + 5)
      sign_in user

      expect do
        post service_orders_path, params: {
          service_order: {
            booking_id: booking.id,
            service_id: service.id,
            service_date: Date.current + 10,
            quantity: 1
          }
        }
      end.not_to change(ServiceOrder, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects an order without a service or date" do
      user = create(:user)
      booking = create(:booking, :confirmed, user: user, check_in: Date.current + 1, check_out: Date.current + 5)
      sign_in user

      expect do
        post service_orders_path, params: { service_order: { booking_id: booking.id, quantity: 1 } }
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
