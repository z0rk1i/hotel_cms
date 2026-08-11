class NotificationMailerPreview < ActionMailer::Preview
  def status_changed
    user = User.first || User.create!(full_name: "Иван Петров", email: "ivan@example.com", password: "password123")
    booking = user.bookings.last || nil
    notifiable = booking || user
    notification = Notification.create!(
      user: user,
      notifiable: notifiable,
      kind: "booking_status",
      title: "Статус брони №1 изменён",
      body: "Бронь — подтверждена.",
      read_at: nil
    )
    NotificationMailer.status_changed(notification)
  end
end
