# Encapsulates public room search: category/amenity filters, price sort and
# availability by dates. Returns the matched rooms (relation or Array after
# availability filtering) plus an optional human-readable date error.
class RoomSearch
  SORT_KEYS = %w[price_asc price_desc].freeze

  attr_reader :rooms, :date_error

  def initialize(params, scope: Room.order(:number))
    @params = params
    @scope = scope
    @date_error = nil
    @rooms = build
  end

  private

  def build
    relation = filter_category(@scope)
    relation = filter_amenities(relation)
    relation = apply_sort(relation)
    apply_availability(relation)
  end

  def filter_category(relation)
    @params["category"].present? ? relation.where(category: @params["category"]) : relation
  end

  def filter_amenities(relation)
    amenities = Array(@params["amenities"]).map(&:presence).compact
    return relation if amenities.empty?

    relation.where("amenities @> ?::jsonb", amenities.to_json)
  end

  def apply_sort(relation)
    return relation unless SORT_KEYS.include?(@params["sort"])

    direction = @params["sort"] == "price_desc" ? :desc : :asc
    relation.order(price_per_night: direction)
  end

  def apply_availability(relation)
    return relation unless @params["check_in"].present? && @params["check_out"].present?

    from = Date.parse(@params["check_in"])
    to = Date.parse(@params["check_out"])
    guests = @params["guests_count"].to_i

    @date_error =
      if to <= from
        "Дата выезда должна быть позже даты заезда"
      elsif from < Date.current
        "Дата заезда не может быть в прошлом"
      end
    return relation if @date_error

    relation.select { |room| room.available_for_booking?(from: from, to: to, guests: guests) }
  rescue Date::Error
    @date_error = "Неверный формат дат"
    relation
  end
end
