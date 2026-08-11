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

  def status_badge_class(status)
    classes = {
      "available" => "bg-emerald-100 text-emerald-700",
      "occupied" => "bg-amber-100 text-amber-700",
      "maintenance" => "bg-red-100 text-red-700",
      "cleaning" => "bg-sky-100 text-sky-700",
      "pending" => "bg-slate-100 text-slate-600",
      "confirmed" => "bg-blue-100 text-blue-700",
      "checked_in" => "bg-emerald-100 text-emerald-700",
      "checked_out" => "bg-slate-200 text-slate-600",
      "cancelled" => "bg-red-100 text-red-600"
    }
    color = classes[status.to_s] || "bg-slate-100 text-slate-600"
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

  def room_status_label(status)
    {
      "available" => "Свободен",
      "occupied" => "Занят",
      "maintenance" => "Ремонт",
      "cleaning" => "Уборка"
    }.fetch(status.to_s, status.to_s)
  end

  def filter_link_class(active)
    base = "px-3 py-1.5 rounded-full text-sm border transition-colors"
    active ? "#{base} bg-slate-900 text-white border-slate-900" : "#{base} bg-white text-slate-600 border-slate-200 hover:bg-slate-50"
  end

  def field_label(form, field, text)
    content_tag :label, text, for: form.field_id(field), class: "block text-sm font-medium text-slate-700 mb-1"
  end

  def field_errors(form, field)
    return if form.object.errors[field].blank?

    content_tag :p, form.object.errors.full_messages_for(field).to_sentence, class: "mt-1 text-sm text-red-600"
  end

  def text_input(form, field, **opts)
    classes = "w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none"
    classes += " border-red-400" if form.object.errors[field].any?
    form.text_field(field, **opts, class: classes)
  end

  def number_input(form, field, **opts)
    classes = "w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none"
    classes += " border-red-400" if form.object.errors[field].any?
    form.number_field(field, **opts, class: classes)
  end

  def text_area(form, field, **opts)
    classes = "w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none"
    classes += " border-red-400" if form.object.errors[field].any?
    form.text_area(field, **opts, class: classes)
  end

  def select_input(form, field, collection, **opts)
    classes = "w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none bg-white"
    classes += " border-red-400" if form.object.errors[field].any?
    form.select(field, collection, { include_blank: true }, **opts, class: classes)
  end
end
