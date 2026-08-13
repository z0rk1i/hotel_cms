class BookingMailer < ApplicationMailer
  def confirmation(stay)
    @stay = stay
    @user = stay.user

    mail(to: @user.email, subject: "Бронь №#{stay.id} создана — ожидает подтверждения")
  end
end
