module ApplicationHelper
  include Pagy::Frontend

  def status_badge_class(status)
    classes = {
      "available" => "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/50 dark:text-emerald-300",
      "occupied" => "bg-amber-100 text-amber-700 dark:bg-amber-900/50 dark:text-amber-300",
      "maintenance" => "bg-red-100 text-red-700 dark:bg-red-900/50 dark:text-red-300",
      "cleaning" => "bg-sky-100 text-sky-700 dark:bg-sky-900/50 dark:text-sky-300",
      "pending" => "bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300",
      "confirmed" => "bg-blue-100 text-blue-700 dark:bg-blue-900/50 dark:text-blue-300",
      "checked_in" => "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/50 dark:text-emerald-300",
      "checked_out" => "bg-slate-200 text-slate-600 dark:bg-slate-700 dark:text-slate-300",
      "cancelled" => "bg-red-100 text-red-600 dark:bg-red-900/50 dark:text-red-300",
      "approved" => "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/50 dark:text-emerald-300",
      "rejected" => "bg-red-100 text-red-600 dark:bg-red-900/50 dark:text-red-300"
    }
    color = classes[status.to_s] || "bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300"
    "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{color}"
  end

  def booking_status_label(status)
    {
      "pending" => "Ожидает",
      "confirmed" => "Подтверждена",
      "checked_in" => "Заселён",
      "checked_out" => "Выселен",
      "cancelled" => "Отменена"
    }.fetch(status.to_s, status.to_s)
  end

def average_rating(reviewable)
    reviews = reviewable.approved_reviews
    return 0 if reviews.empty?

    (reviews.sum(&:rating).to_f / reviews.size).round(1)
  end

  def russian_pluralize(count, one, few, many)
    remainder10 = count % 10
    remainder100 = count % 100

    return many if remainder100 >= 11 && remainder100 <= 14
    return one if remainder10 == 1
    return few if remainder10 >= 2 && remainder10 <= 4

    many
  end

def service_order_status_label(status)
    {
      "pending" => "Ожидает",
      "confirmed" => "Подтверждён",
      "cancelled" => "Отменён"
    }.fetch(status.to_s, status.to_s)
  end

  def review_status_label(status)
    {
      "pending" => "На модерации",
      "approved" => "Одобрен",
      "rejected" => "Отклонён"
    }.fetch(status.to_s, status.to_s)
  end

  def active_booking?(user = current_user)
    return false if user.blank?

    user.bookings.active_for_service.exists?
  end
end
