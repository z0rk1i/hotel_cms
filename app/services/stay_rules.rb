class StayRules
  def self.min_nights_between(check_in:, check_out:)
    PricePeriod.where("starts_on <= ? AND ends_on >= ?", check_out - 1, check_in)
               .pluck(:min_nights)
               .compact
               .max
               .to_i
  end

  def self.closed_dates_between(check_in:, check_out:)
    ClosedDate.where(date: check_in...check_out).order(:date).pluck(:date)
  end

  def self.closed_in?(check_in:, check_out:)
    closed_dates_between(check_in: check_in, check_out: check_out).any?
  end

  def self.min_stay_message(min_nights)
    "Минимальный срок проживания — #{min_nights} #{nights_word(min_nights)}"
  end

  def self.nights_word(count)
    return "ночей" if (count % 100).between?(11, 14)

    case count % 10
    when 1 then "ночь"
    when 2..4 then "ночи"
    else "ночей"
    end
  end
end
