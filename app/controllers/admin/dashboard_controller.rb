module Admin
  class DashboardController < BaseController
    def index
      today = Date.current
      @stats = {
        rooms_total: Room.count,
        rooms_available: Room.available_now.count,
        rooms_occupied: Room.where(status: :occupied).count,
        active_bookings: Booking.active.count,
        upcoming_check_ins: Booking.upcoming.limit(8),
        checked_in_now: Booking.checked_in_now.includes(:room, :guest),
        monthly_revenue: Booking.checked_out.by_month(today).sum(:total_price),
        occupancy_rate: occupancy_rate(today)
      }
    end

    private

    def occupancy_rate(date)
      nights_in_month = date.end_of_month.day
      available_nights = Room.count * nights_in_month
      return 0 if available_nights.zero?

      booked_nights = Booking.active.for_period(date.beginning_of_month, date.end_of_month.next_day)
                              .sum { |b| [ [ b.check_out, date.end_of_month.next_day ].min - [ b.check_in, date.beginning_of_month ].max, 0 ].max }
      (booked_nights.to_f / available_nights * 100).round(1)
    end
  end
end
