class RoomAvailability
  include Dry::Monads[:result]

  NON_BOOKABLE_STATUSES = %i[maintenance cleaning].freeze

  def call(check_in:, check_out:, exclude_room_id: nil)
    result = validate_dates(check_in, check_out)
    return result if result.failure?

    start_date, end_date = result.value!
    Success(available_rooms(start_date, end_date, exclude_room_id))
  end

  private

  def validate_dates(check_in, check_out)
    start_date = parse_date(check_in)
    end_date = parse_date(check_out)
    return Failure(:invalid_dates) if start_date.nil? || end_date.nil?
    return Failure(:invalid_range) if end_date <= start_date

    Success([ start_date, end_date ])
  end

  def parse_date(value)
    DateParams.parse(value)
  end

  def available_rooms(start_date, end_date, exclude_room_id)
    occupied = Booking.active_overlapping(start_date, end_date).select(:room_id)
    occupied = occupied.where.not(room_id: exclude_room_id) if exclude_room_id.present?

    Room.where.not(id: occupied)
        .where.not(status: NON_BOOKABLE_STATUSES)
        .bookable_on(start_date, end_date)
        .order(:floor, :number)
        .includes(:category)
        .map do |room|
          {
            id: room.id,
            label: room.label,
            price: room.price_per_night.to_f,
            total_price: NightlyPricing.new(room: room, check_in: start_date, check_out: end_date).total,
            capacity: room.capacity
          }
        end
  end
end
