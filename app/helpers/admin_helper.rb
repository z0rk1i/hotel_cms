module AdminHelper
  def nav_link_class(path)
    active = request.path == path || request.path.start_with?("#{path}/")
    base = "flex items-center gap-2 px-3 py-2 rounded-lg transition-colors"
    active ? "#{base} bg-slate-800 text-white" : "#{base} hover:bg-slate-800 hover:text-white"
  end

  def money(amount)
    return "—" if amount.nil?

    number_to_currency(amount, unit: "₽", separator: ",", delimiter: " ", precision: 0)
  end

  def room_status_label(status)
    {
      "available" => "Свободен",
      "occupied" => "Занят",
      "maintenance" => "Ремонт",
      "cleaning" => "Уборка"
    }.fetch(status.to_s, status.to_s)
  end

  def calendar_booking_class(status)
    colors = {
      "pending" => "bg-slate-200 text-slate-700 border-slate-300 dark:bg-slate-700 dark:text-slate-200 dark:border-slate-600",
      "confirmed" => "bg-blue-100 text-blue-800 border-blue-300 dark:bg-blue-900/50 dark:text-blue-100 dark:border-blue-700",
      "checked_in" => "bg-emerald-100 text-emerald-800 border-emerald-300 dark:bg-emerald-900/50 dark:text-emerald-100 dark:border-emerald-700",
      "checked_out" => "bg-slate-100 text-slate-500 border-slate-200 dark:bg-slate-800 dark:text-slate-400 dark:border-slate-700",
      "cancelled" => "bg-red-100 text-red-700 border-red-300 dark:bg-red-900/50 dark:text-red-300 dark:border-red-700"
    }
    colors.fetch(status.to_s, "bg-slate-200 text-slate-700 border-slate-300 dark:bg-slate-700 dark:text-slate-200 dark:border-slate-600")
  end

  RUSSIAN_MONTHS = %w[января февраля марта апреля мая июня июля августа сентября октября ноября декабря].freeze
  RUSSIAN_MONTHS_NOM = %w[Январь Февраль Март Апрель Май Июнь Июль Август Сентябрь Октябрь Ноябрь Декабрь].freeze
  RUSSIAN_DAYS = %w[Вс Пн Вт Ср Чт Пт Сб].freeze

  def russian_day_abbr(date)
    RUSSIAN_DAYS[date.wday]
  end

  def russian_month_header(date)
    "#{RUSSIAN_MONTHS_NOM[date.month - 1]} #{date.year}"
  end

  def filter_link_class(active)
    base = "px-3 py-1.5 rounded-full text-sm border transition-colors"
    if active
      "#{base} bg-slate-900 text-white border-slate-900"
    else
      "#{base} bg-white text-slate-600 border-slate-200 hover:bg-slate-50 " \
        "dark:bg-slate-800 dark:text-slate-300 dark:border-slate-700 dark:hover:bg-slate-700"
    end
  end

  def field_label(form, field, text)
    content_tag :label, text, for: form.field_id(field), class: "block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
  end

  def field_errors(form, field)
    return if form.object.errors[field].blank?

    content_tag :p, form.object.errors.full_messages_for(field).to_sentence, class: "mt-1 text-sm text-red-600 dark:text-red-400"
  end

  def text_input(form, field, **opts)
    classes = input_classes(form, field)
    form.text_field(field, **opts, class: classes)
  end

  def number_input(form, field, **opts)
    classes = input_classes(form, field)
    form.number_field(field, **opts, class: classes)
  end

  def date_input(form, field, **opts)
    classes = input_classes(form, field)
    form.date_field(field, **opts, class: classes)
  end

  def text_area(form, field, **opts)
    classes = input_classes(form, field)
    form.text_area(field, **opts, class: classes)
  end

  def select_input(form, field, collection, **opts)
    classes = input_classes(form, field) + " bg-white dark:bg-slate-800"
    form.select(field, collection, { include_blank: true }, **opts, class: classes)
  end

  private

  def input_classes(form, field)
    classes = "w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none " \
              "bg-white dark:bg-slate-800 dark:text-slate-100 dark:placeholder-slate-400 dark:border-slate-600 " \
              "focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
    classes += " border-red-400 dark:border-red-500" if form.object.errors[field].any?
    classes
  end
end
