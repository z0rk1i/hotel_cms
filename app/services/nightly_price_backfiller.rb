class NightlyPriceBackfiller
  def self.run(scope: Booking.all)
    scope.where(price_frozen_on: nil).find_each { |booking| backfill(booking) }
  end

  def self.backfill(booking)
    return if booking.price_frozen_on.present? || booking.room.blank?

    pricing = NightlyPricing.new(room: booking.room, check_in: booking.check_in, check_out: booking.check_out)
    ActiveRecord::Base.transaction do
      booking.nightly_prices.delete_all
      pricing.entries.each do |entry|
        booking.nightly_prices.create!(date: entry.date, amount: entry.amount)
      end
      booking.update_column(:price_frozen_on, Date.current)
    end
  end
end
