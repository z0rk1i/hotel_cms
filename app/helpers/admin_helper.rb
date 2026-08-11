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
