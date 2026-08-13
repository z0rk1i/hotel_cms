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

  def image_thumb(attachment, size: [ 640, 400 ])
    attachment.variant(resize_to_fill: size)
  end

  def selected_amenity_ids
    Array(params[:amenities]).map(&:to_i).reject(&:zero?)
  end

  def amenity_filter_link(amenity)
    selected = selected_amenity_ids
    currently_selected = selected.include?(amenity.id)
    toggled = currently_selected ? selected - [ amenity.id ] : selected + [ amenity.id ]
    path = rooms_search_path(amenities: toggled)
    link_to amenity.name, path, class: amenity_chip_class(currently_selected)
  end

  def amenity_chip_class(selected)
    base = "px-4 py-1.5 rounded-full text-sm font-medium border transition-colors"
    if selected
      "#{base} bg-indigo-600 text-white border-indigo-600"
    else
      "#{base} bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 border-slate-300 dark:border-slate-600 hover:border-indigo-400"
    end
  end

  def selected_category_id
    params[:category_id].to_i
  end

  def rooms_search_path(overrides)
    query = params.slice(:check_in, :check_out, :guests_count, :amenities, :category_id, :sort)
                  .to_unsafe_h
                  .merge(overrides)
                  .reject { |_, value| value.blank? || value == [] || value == [ "" ] }
    root_path(query.symbolize_keys.merge(anchor: "rooms"))
  end

  def sort_link_class(value)
    base = "px-3 py-1.5 rounded-lg text-sm font-medium border transition-colors"
    if params[:sort] == value
      "#{base} bg-slate-900 text-white border-slate-900 dark:bg-indigo-600 dark:border-indigo-600"
    else
      "#{base} bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 border-slate-300 dark:border-slate-600 hover:border-indigo-400"
    end
  end

  def availability_search?
    params[:check_in].present? || params[:check_out].present?
  end

  def format_search_dates
    return "" unless availability_search?

    check_in = DateParams.parse(params[:check_in])
    check_out = DateParams.parse(params[:check_out])
    return "на выбранные даты" if check_in.nil? || check_out.nil?

    "на #{I18n.l(check_in, format: :long)} — #{I18n.l(check_out, format: :long)}"
  end

  def search_guests_label
    return "" unless params[:guests_count].to_i.positive?

    "для #{params[:guests_count].to_i} #{russian_pluralize(params[:guests_count].to_i, "гостя", "гостей", "гостей")}"
  end
end
