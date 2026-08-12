require "time"

class Reports::PeriodReport
  ACTIVE_STATUSES = %w[confirmed checked_in checked_out].freeze
  MAX_RANGE_DAYS = 92

  attr_reader :from, :to, :dates

  def initialize(from:, to:)
    @from = from
    @to = clamp_to(to)
    @dates = (@from..@to).to_a
  end

  def night_rows
    @night_rows ||= dates.map do |date|
      sold = sold_by_date[date]
      {
        date: date,
        plan: plan_by_date[date].to_i,
        fact: fact_by_date[date].to_i,
        sold: sold,
        total: total_rooms,
        occupancy: occupancy(sold, total_rooms)
      }
    end
  end

  def category_rows
    @category_rows ||= begin
      rooms_by_category = Room.preload(:category).group_by { |room| room.category }
      rooms_by_category.map do |category, rooms|
        capacity = rooms.size * dates.size
        sold = rooms.sum { |room| nights_by_room[room.id] }
        {
          category: category,
          rooms: rooms.size,
          capacity_nights: capacity,
          sold_nights: sold,
          occupancy: occupancy(sold, capacity)
        }
      end
    end
  end

  def summary
    sold_nights = dates.sum { |date| sold_by_date[date] }
    {
      fact: fact_by_date.values.sum,
      plan: plan_by_date.values.sum,
      occupancy: occupancy(sold_nights, dates.size * total_rooms)
    }
  end

  def overlapping_bookings
    @overlapping_bookings ||= Booking
      .select(:id, :room_id, :check_in, :check_out)
      .where(status: ACTIVE_STATUSES)
      .where("check_in <= ? AND check_out > ?", @to, @from)
  end

  private

  def total_rooms
    @total_rooms ||= Room.count
  end

  def nights_by_room
    @nights_by_room ||= begin
      nights = Hash.new(0)
      overlapping_bookings.each do |booking|
        start_date = [ booking.check_in, @from ].max
        end_date = [ booking.check_out, @to + 1 ].min
        nights[booking.room_id] += (end_date - start_date).to_i
      end
      nights
    end
  end

  def sold_by_date
    @sold_by_date ||= begin
      sold = Hash.new(0)
      overlapping_bookings.each do |booking|
        start_date = [ booking.check_in, @from ].max
        end_date = [ booking.check_out, @to + 1 ].min
        (start_date...end_date).each { |date| sold[date] += 1 }
      end
      sold
    end
  end

  def plan_by_date
    @plan_by_date ||= BookingNightlyPrice
      .joins(:booking)
      .where(date: dates, bookings: { status: ACTIVE_STATUSES })
      .group(:date)
      .sum(:amount)
      .transform_keys(&:to_date)
  end

  def fact_by_date
    @fact_by_date ||= Payment
      .where(paid_at: @from.beginning_of_day..@to.end_of_day)
      .group("DATE(paid_at)")
      .sum(:amount)
      .transform_keys(&:to_date)
  end

  def occupancy(numerator, denominator)
    return 0.0 if denominator.zero?

    ((numerator.to_f / denominator) * 100).round(1)
  end

  def clamp_to(date)
    limit = @from + MAX_RANGE_DAYS
    [ date, limit ].min
  end
end
