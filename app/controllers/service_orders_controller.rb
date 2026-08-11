class ServiceOrdersController < ApplicationController
  layout "public"

  before_action :authenticate_user!

  def new
    @service_order = ServiceOrder.new
    @service_order.service_date = Date.current + 1
    @service_order.quantity = 1
    @service_order.service_id = params[:service_id] if params[:service_id].present?
    @services = Service.order(:name)
  end

  def create
    @service_order = current_user.service_orders.new(service_order_params)
    @services = Service.order(:name)

    if @service_order.save
      redirect_to account_path, notice: "Заказ услуги оформлен! Ожидает подтверждения отеля."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def cancel
    @service_order = current_user.service_orders.find(params[:id])
    @service_order.cancelled! if @service_order.pending?
    redirect_to account_path, notice: "Заказ услуги отменён."
  end

  private

  def service_order_params
    params.require(:service_order).permit(:service_id, :service_date, :quantity, :notes)
  end
end
