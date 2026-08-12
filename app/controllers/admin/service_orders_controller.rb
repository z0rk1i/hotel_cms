module Admin
  class ServiceOrdersController < BaseController
    before_action :set_service_order, only: %i[confirm cancel]

    def index
      @service_orders = ServiceOrder.includes(:service, :user)
      @service_orders = @service_orders.where(status: params[:status]) if params[:status].present?
      @service_orders = @service_orders.ordered
      @service_orders = paginate(@service_orders)
    end

    def confirm
      @service_order.confirmed!
      redirect_back_or admin_service_orders_path, notice: "Заказ услуги подтверждён."
    end

    def cancel
      @service_order.cancelled!
      redirect_back_or admin_service_orders_path, notice: "Заказ услуги отменён."
    end

    private

    def set_service_order
      @service_order = ServiceOrder.find(params[:id])
    end
  end
end
