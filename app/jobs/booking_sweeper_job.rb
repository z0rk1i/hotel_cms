class BookingSweeperJob < ApplicationJob
  queue_as :default

  def perform
    auto_check_out_stale_stays
    cancel_no_shows
    send_check_in_reminders
  end

  private

  def auto_check_out_stale_stays
    Booking.checked_in.where("check_out <= ?", Date.current).find_each do |booking|
      booking.transition_to(:checked_out)
    end
  end

  def cancel_no_shows
    Booking.where(status: %i[pending confirmed]).where("check_in < ?", Date.current).find_each do |booking|
      booking.transition_to(:cancelled)
      apply_no_show_fee(booking)
    end
  end

  def apply_no_show_fee(booking)
    return if booking.no_show_fee.present?

    fee = booking.nightly_prices.find_by(date: booking.check_in)&.amount
    fee ||= begin
      nights = (booking.check_out - booking.check_in).to_i
      nights.positive? ? booking.total_price.to_d / nights : 0
    end

    booking.update!(no_show_fee: fee.round(2)) if fee.to_d.positive?
  end

  def send_check_in_reminders
    Booking.confirmed.where(check_in: Date.current + 1).includes(:user).find_each do |booking|
      next unless booking.user&.email_deliverable?

      BookingMailer.check_in_reminder(booking).deliver_later
    end
  end
end
