module BookingPricing
  extend ActiveSupport::Concern

  included do
    before_save :calculate_total_price,
                if: -> { room && check_in && check_out && (new_record? || room_id_changed? || check_in_changed? || check_out_changed?) }
  end

  private

  def calculate_total_price
    pricing = NightlyPricing.new(room: room, check_in: check_in, check_out: check_out)
    self.total_price = pricing.total
    self.nightly_prices = pricing.entries.map { |entry| BookingNightlyPrice.new(date: entry.date, amount: entry.amount) }
    self.price_frozen_on = Date.current
  end
end
