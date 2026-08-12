class NightlyPricing
  WEEKEND_NIGHTS = [ 5, 6 ].freeze # пятница и суббота

  Entry = Struct.new(:date, :amount, keyword_init: true)

  def initialize(room:, check_in:, check_out:)
    @room = room
    @check_in = check_in
    @check_out = check_out
  end

  def entries
    (@check_in...@check_out).map { |date| Entry.new(date: date, amount: price_for_night(date)) }
  end

  def total
    entries.sum(&:amount)
  end

  private

  def price_for_night(date)
    @room.price_per_night * seasonal_multiplier_for(date) * weekend_multiplier_for(date)
  end

  def seasonal_multiplier_for(date)
    price_periods.find { |period| period.starts_on <= date && period.ends_on >= date }&.multiplier || 1
  end

  def price_periods
    @price_periods ||= PricePeriod.where("starts_on <= ? AND ends_on >= ?", @check_out - 1, @check_in)
                                  .order(:starts_on, :id)
                                  .to_a
  end

  def weekend_multiplier_for(date)
    WEEKEND_NIGHTS.include?(date.wday) ? @room.weekend_multiplier.to_f : 1.0
  end
end
