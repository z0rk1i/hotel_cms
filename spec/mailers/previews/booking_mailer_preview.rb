class BookingMailerPreview < ActionMailer::Preview
  def created
    BookingMailer.created(booking)
  end

  def confirmed
    BookingMailer.confirmed(booking)
  end

  def cancelled
    BookingMailer.cancelled(booking)
  end

  private

  def booking
    user = User.first || User.create!(full_name: "Иван Петров", email: "ivan@example.com", password: "password123")
    user.bookings.last || user.bookings.create!(
      guest: Guest.create!(full_name: "Иван Петров", email: "ivan@example.com", phone: "+7 900 000-00-00"),
      room: Room.first || Room.create!(number: 101, capacity: 2),
      check_in: Date.current + 2,
      check_out: Date.current + 4,
      guests_count: 2
    )
  end
end
