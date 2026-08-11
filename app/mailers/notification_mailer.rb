class NotificationMailer < ApplicationMailer
  def status_changed(notification)
    @notification = notification
    @user = notification.user

    mail(to: @user.email, subject: @notification.title)
  end
end
