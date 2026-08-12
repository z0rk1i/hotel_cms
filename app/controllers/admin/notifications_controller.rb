module Admin
  class NotificationsController < BaseController
    def index
      @notifications = Notification.for_admin.ordered
    end

    def read
      notification = Notification.for_admin.find(params[:id])
      notification.update!(read_at: Time.current)
      redirect_to admin_notifications_path, notice: "Уведомление отмечено прочитанным."
    end

    def mark_all_read
      Notification.for_admin.unread.update_all(read_at: Time.current)
      redirect_to admin_notifications_path, notice: "Все уведомления прочитаны."
    end
  end
end
