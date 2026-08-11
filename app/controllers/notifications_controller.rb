class NotificationsController < ApplicationController
  layout "public"

  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications.ordered
  end

  def read
    notification = current_user.notifications.find(params[:id])
    notification.update!(read_at: Time.current)
    redirect_back fallback_location: notifications_path, notice: "Уведомление отмечено прочитанным."
  end

  def mark_all_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_to notifications_path, notice: "Все уведомления прочитаны."
  end
end
