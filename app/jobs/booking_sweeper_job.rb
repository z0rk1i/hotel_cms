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
    end
  end

  def send_check_in_reminders
    Booking.confirmed.where(check_in: Date.current + 1).includes(:user).find_each do |booking|
      next unless booking.user&.email_deliverable?

      BookingMailer.check_in_reminder(booking).deliver_later
    end
  end
end
