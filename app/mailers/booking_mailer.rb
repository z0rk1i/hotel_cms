class BookingMailer < ApplicationMailer
  def created(booking)
    @booking = booking
    @user = booking.user

    mail(to: @user.email, subject: "Бронь №#{booking.id} создана — ожидает подтверждения")
  end

  def confirmed(booking)
    @booking = booking
    @user = booking.user

    mail(to: @user.email, subject: "Бронь №#{booking.id} подтверждена")
  end

  def cancelled(booking)
    @booking = booking
    @user = booking.user

    mail(to: @user.email, subject: "Бронь №#{booking.id} отменена")
  end
end
