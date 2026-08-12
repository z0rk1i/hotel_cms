require "rails_helper"

RSpec.describe NotificationMailer, type: :mailer do
  let(:user) { create(:user) }
  let(:notification) do
    create(:notification, user: user,
                          title: "Статус брони №1 изменён",
                          body: "Бронь — подтверждена.")
  end

  describe "#status_changed" do
    let(:mail) { described_class.status_changed(notification) }

    it "sends to the user's email with the notification title as subject" do
      expect(mail.to).to eq([ user.email ])
      expect(mail.subject).to eq("Статус брони №1 изменён")
    end

    it "renders the notification body in HTML and text" do
      expect(mail.text_part.body.decoded).to include("Бронь — подтверждена.")
      expect(mail.html_part.body.decoded).to include("Бронь — подтверждена.")
    end

    it "links to the personal account" do
      expect(mail.html_part.body.decoded).to include(account_url)
    end
  end

  describe Notification, type: :model do
    it "does not enqueue an email for placeholder OAuth addresses" do
      user = create(:user, provider: "vkontakte", uid: "123", email: "vkontakte-123@example.com")
      notification = build(:notification, user: user, kind: "service_order_status")

      expect do
        notification.save!
      end.not_to change(enqueued_jobs, :count)
    end

    it "enqueues an email when the user has a deliverable address" do
      notification = build(:notification, user: create(:user, email: "real@example.org"), kind: "service_order_status")

      expect do
        notification.save!
      end.to change(enqueued_jobs, :count).by(1)
    end

    it "does not enqueue a notification email for booking status changes (BookingMailer covers it)" do
      notification = build(:notification, user: create(:user, email: "real@example.org"))

      expect do
        notification.save!
      end.not_to change(enqueued_jobs, :count)
    end
  end
end
