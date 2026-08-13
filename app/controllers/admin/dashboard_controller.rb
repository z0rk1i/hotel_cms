module Admin
  class DashboardController < BaseController
    def index
      today = Date.current
      checked_in_now = Booking.checked_in_now
      occupied_room_ids = checked_in_now.select(:room_id).distinct
      booked_tonight_ids = Booking.occupying_overlapping(today, today + 1).select(:room_id)
      unavailable_ids = Room.where(status: :maintenance).select(:id)
      unavailable_ids = unavailable_ids.or(Room.in_unavailability_window(today, today + 1).select(:id))

      @stats = {
        rooms_total: Room.count,
        rooms_available: Room.where.not(id: booked_tonight_ids).where.not(id: unavailable_ids).count,
        rooms_occupied: occupied_room_ids.count,
        active_bookings: Booking.active.count,
        upcoming_check_ins: Booking.upcoming.where(status: %i[pending confirmed]).includes(:guest, :room).limit(8),
        checked_in_now: checked_in_now.includes(:room, :guest),
        monthly_revenue: Payment.where(paid_at: today.beginning_of_month..today.end_of_month).sum(:amount),
        monthly_booked_revenue: Booking.checked_out.where(check_out: today.beginning_of_month..today.end_of_month).sum(:total_price),
        occupancy_rate: occupancy_rate(today)
      }
    end

    private

    def occupancy_rate(date)
      sellable_rooms = Room.where.not(status: :maintenance).count
      nights_in_month = date.end_of_month.day
      available_nights = sellable_rooms * nights_in_month
      return 0 if available_nights.zero?

      booked_nights = Booking.active.where.not(status: :pending)
                              .for_period(date.beginning_of_month, date.end_of_month.next_day)
                              .sum { |b| [ [ b.check_out, date.end_of_month.next_day ].min - [ b.check_in, date.beginning_of_month ].max, 0 ].max }
      (booked_nights.to_f / available_nights * 100).round(1)
    end
  end
end
