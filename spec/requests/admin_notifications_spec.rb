require "rails_helper"

RSpec.describe "Admin notifications", type: :request do
  before { sign_in create(:administrator) }

  describe "GET /admin/notifications" do
    it "lists admin notifications" do
      create(:notification, to_admin: true, kind: "new_booking", title: "Новая бронь №12")
      create(:notification, to_admin: false, kind: "booking_status", title: "Статус брони изменён")

      get admin_notifications_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Новая бронь №12")
      expect(response.body).not_to include("Статус брони изменён")
    end

    it "shows the unread count badge in the admin layout" do
      create(:notification, to_admin: true)

      get admin_root_path

      topbar = response.body[/Уведомления(.{0,200})/m, 1]
      expect(topbar).to match(/>\d+</)
    end
  end

  describe "PATCH /admin/notifications/:id/read" do
    it "marks a single notification as read" do
      notification = create(:notification, to_admin: true, kind: "new_booking")

      patch read_admin_notification_path(notification)

      expect(notification.reload.read_at).to be_present
      expect(response).to redirect_to(admin_notifications_path)
    end
  end

  describe "POST /admin/notifications/mark_all_read" do
    it "marks all admin notifications as read" do
      create(:notification, to_admin: true, kind: "new_booking")
      create(:notification, to_admin: true, kind: "new_review")

      post mark_all_read_admin_notifications_path

      expect(Notification.for_admin.unread).to be_empty
      expect(response).to redirect_to(admin_notifications_path)
    end
  end
end
