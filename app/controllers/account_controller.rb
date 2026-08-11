class AccountController < ApplicationController
  layout "public"

  before_action :authenticate_user!

  def show
    @bookings = current_user.bookings.includes(:room).order(check_in: :desc)
    @service_orders = current_user.service_orders.includes(:service).ordered
    @notifications = current_user.notifications.ordered.limit(5)
    @unread_notifications = current_user.notifications.unread
  end
end
