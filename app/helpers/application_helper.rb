require "rack/utils"

module ApplicationHelper
  def h(text)
    Rack::Utils.escape_html(text.to_s)
  end

  def l(date, format: :default)
    date.nil? ? "" : I18n.l(date, format: format)
  end

  def money(amount)
    int = (amount || 0).to_f.round
    sign = int.negative? ? "-" : ""
    "#{sign}₽#{int.abs.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1 ').reverse}"
  end
  module_function :money

  def russian_pluralize(count, one, few, many)
    count = count.to_i
    rem10 = count % 10
    rem100 = count % 100
    return many if rem100.between?(11, 14)
    return one if rem10 == 1
    return few if rem10.between?(2, 4)

    many
  end

  def simple_format(text)
    text.to_s.split(/\n\n+/).map { |p| "<p>#{h(p).gsub("\n", "<br>")}</p>" }.join
  end

  def link_to(text, path, options = {})
    attrs = options.reject { |_, v| v.nil? }.map { |k, v| %( #{k}="#{h(v)}") }.join
    %(<a href="#{h(path)}"#{attrs}>#{text}</a>)
  end

  def content_tag(name, content = nil, options = {})
    attrs = options.reject { |_, v| v.nil? }.map { |k, v| %( #{k}="#{h(v)}") }.join
    %(<#{name}#{attrs}>#{content}</#{name}>)
  end

  def content_for(name, value = nil)
    @content_for ||= {}
    value.nil? ? @content_for[name] : @content_for[name] = value
  end

  def partial(name, locals = {})
    haml(name.to_sym, locals: locals, layout: false)
  end

  def image_tag(src, options = {})
    attrs = { src: src }.merge(options).reject { |_, v| v.nil? }.map { |k, v| %( #{k}="#{h(v)}") }.join
    %(<img#{attrs}>)
  end

  def button_to(text, path, method: :post, class: nil, confirm: nil)
    hidden = []
    hidden << %(<input type="hidden" name="_method" value="#{method}">) unless %i[get post].include?(method.to_sym)
    hidden << %(<input type="hidden" name="authenticity_token" value="#{h(authenticity_token)}">)
    onsubmit = confirm ? %( onsubmit="return confirm('#{h(confirm)}')") : ""
    klass = binding.local_variable_get(:class)
    %(<form action="#{h(path)}" method="post" style="display:inline"#{onsubmit}>#{hidden.join}#{csrf_field}<button type="submit" class="#{h(klass)}">#{text}</button></form>)
  end

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
      "pending_review" => "bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300"
    }
    color = classes[status.to_s] || "bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300"
    "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{color}"
  end

  def stay_status_label(status)
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

  def payment_method_label(method)
    {
      "cash" => "Наличные",
      "card" => "Карта",
      "transfer" => "Перевод"
    }.fetch(method.to_s, method.to_s)
  end

  def offered_amenities
    Room.order(:amenities).pluck(:amenities).flatten.compact.uniq.sort
  end

  def availability_search?
    params["check_in"].present? || params["check_out"].present?
  end

  def format_search_dates
    return "" unless availability_search?

    check_in = safe_date_parse(params["check_in"])
    check_out = safe_date_parse(params["check_out"])
    return "на выбранные даты" if check_in.nil? || check_out.nil?

    "на #{I18n.l(check_in, format: :long)} — #{I18n.l(check_out, format: :long)}"
  end

  def search_guests_label
    return "" unless params["guests_count"].to_i.positive?

    count = params["guests_count"].to_i
    "для #{count} #{russian_pluralize(count, "гостя", "гостей", "гостей")}"
  end

  def selected_amenities
    Array(params["amenities"]).map(&:presence).compact
  end

  def amenity_filter_link(amenity)
    selected = selected_amenities
    currently_selected = selected.include?(amenity)
    toggled = currently_selected ? selected - [ amenity ] : selected + [ amenity ]
    link_to amenity, rooms_search_path(amenities: toggled), class: amenity_chip_class(currently_selected)
  end

  def amenity_chip_class(selected)
    base = "px-4 py-1.5 rounded-full text-sm font-medium border transition-colors"
    if selected
      "#{base} bg-indigo-600 text-white border-indigo-600"
    else
      "#{base} bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 border-slate-300 dark:border-slate-600 hover:border-indigo-400"
    end
  end

  def rooms_search_path(overrides = {})
    base = {}
    %w[check_in check_out guests_count amenities category sort].each do |k|
      base[k] = params[k] if params[k].present?
    end
    base.merge!(overrides.transform_keys(&:to_s))
    base.reject! { |_, v| v.blank? || v == [] || v == [ "" ] }
    path_with("/", base.merge(anchor: "rooms"))
  end

  def sort_link_class(value)
    base = "px-3 py-1.5 rounded-lg text-sm font-medium border transition-colors"
    if params["sort"] == value
      "#{base} bg-slate-900 text-white border-slate-900 dark:bg-indigo-600 dark:border-indigo-600"
    else
      "#{base} bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 border-slate-300 dark:border-slate-600 hover:border-indigo-400"
    end
  end

  private

  def safe_date_parse(value)
    return nil if value.blank?

    Date.parse(value)
  rescue Date::Error, ArgumentError
    nil
  end
end
