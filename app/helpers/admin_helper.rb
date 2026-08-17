module AdminHelper
  def nav_link_class(path)
    active = request.path == path || request.path.start_with?("#{path}/")
    base = "flex items-center gap-2 px-3 py-2 rounded-lg transition-colors"
    active ? "#{base} bg-slate-800 text-white" : "#{base} hover:bg-slate-800 hover:text-white"
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

  def field_label(id, text, required: false)
    suffix = required ? " *" : ""
    %(<label for="#{h(id)}" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">#{h(text)}#{suffix}</label>)
  end

  def field_errors(object, field)
    return "" if object.errors[field].blank?

    content_tag :p, object.errors.full_messages_for(field).to_sentence, class: "mt-1 text-sm text-red-600 dark:text-red-400"
  end

  def input_class(object, field)
    classes = "w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none " \
              "bg-white dark:bg-slate-800 dark:text-slate-100 dark:placeholder-slate-400 dark:border-slate-600 " \
              "focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
    classes += " border-red-400 dark:border-red-500" if object.errors[field].any?
    classes
  end
end
