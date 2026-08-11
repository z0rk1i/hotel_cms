require "rails_helper"

RSpec.describe "Notifications", type: :request do
  describe "GET /notifications" do
    it "requires authentication" do
      get notifications_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "lists only the current user's notifications" do
      user = create(:user)
      own = create(:notification, user: user)
      create(:notification, user: create(:user))

      sign_in user
      get notifications_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(own.title)
    end
  end

  describe "PATCH /notifications/:id/read" do
    it "marks a notification as read" do
      user = create(:user)
      notification = create(:notification, user: user)
      sign_in user

      patch read_notification_path(notification)
      expect(notification.reload).to be_read
    end

    it "does not allow reading someone else's notification" do
      notification = create(:notification, user: create(:user))
      sign_in create(:user)

      patch read_notification_path(notification)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /notifications/mark_all_read" do
    it "marks all unread notifications as read" do
      user = create(:user)
      create_list(:notification, 2, user: user, read_at: nil)
      sign_in user

      post mark_all_read_notifications_path
      expect(user.notifications.reload.unread.count).to eq(0)
      expect(response).to redirect_to(notifications_path)
    end
  end
end
