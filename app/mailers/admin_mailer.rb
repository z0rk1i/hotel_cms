class AdminMailer < ApplicationMailer
  helper_method :reviewable_label

  def new_booking(booking)
    @booking = booking

    mail(to: Administrator.pluck(:email), subject: "Новая бронь №#{booking.id} — требуется подтверждение")
  end

  def new_review(review)
    @review = review

    mail(to: Administrator.pluck(:email), subject: "Новый отзыв ожидает модерации")
  end

  private

  def reviewable_label(review)
    case review.reviewable_type
    when "Room" then "Номер №#{review.reviewable.number}"
    when "Service" then review.reviewable.name
    else review.reviewable_type
    end
  end
end
