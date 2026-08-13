class Room < ApplicationRecord
  WEEKEND_DAYS = [ 5, 6 ].freeze

  has_many :stays, dependent: :restrict_with_error
  has_many_attached :photos

  validates :number, presence: true, uniqueness: true
  validates :category, presence: true
  validates :floor, :capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :price_per_night, numericality: { greater_than_or_equal_to: 0 }
  validates :weekend_multiplier, numericality: { greater_than: 0 }
  validates :min_nights, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :status, inclusion: { in: %w[available maintenance cleaning] }

  scope :by_status, ->(status) { where(status: status) }
  scope :by_category, ->(category) { where(category: category) }
  scope :search, lambda { |query|
    where("number ILIKE :q OR category ILIKE :q", q: "%#{query}%")
  }

  def available?
    status == "available"
  end

  def maintenance?
    status == "maintenance"
  end

  def cleaning?
    status == "cleaning"
  end

  def bookable?
    !maintenance?
  end

  def unavailable_during?(from, to)
    return false if unavailable_from.nil? || unavailable_until.nil?

    unavailable_from < to && unavailable_until > from
  end

  def overlapping_stays(from, to)
    stays.where(status: %w[pending confirmed checked_in checked_out])
         .where("check_in < ? AND check_out > ?", to, from)
  end

  def occupied_now?
    stays.checked_in.overlapping_period(Date.current, Date.current + 1).exists?
  end

  def available_on?(from, to)
    return false unless bookable?

    !unavailable_during?(from, to) && overlapping_stays(from, to).none?
  end

  def price_for_night(date)
    amount = price_per_night.to_f
    amount *= weekend_multiplier.to_f if WEEKEND_DAYS.include?(date.wday)
    amount
  end

  def price_for_stay(from, to)
    nights(from, to).sum { |date| price_for_night(date) }
  end

  def nightly_breakdown(from, to)
    nights(from, to).map { |date| { date: date, amount: price_for_night(date) } }
  end

  def nights(from, to)
    (from...to).to_a
  end

  def next_free_window(horizon: 60.days.from_now)
    last = [ horizon.to_date, (unavailable_until || horizon) + 1 ].compact.max
    cursor = Date.current
    while cursor <= last
      from = cursor
      to = from + min_nights
      return { check_in: from, check_out: to, price: price_for_stay(from, to) } if available_on?(from, to)

      cursor += 1
    end
    nil
  end

  def approved_reviews
    (reviews || []).select { |review| review["status"] == "approved" }
  end

  def add_review(user:, rating:, body:)
    entry = {
      "user_id" => user.id,
      "author" => user.full_name.to_s.squish,
      "rating" => rating.to_i,
      "body" => body,
      "status" => "pending",
      "created_at" => Time.current.iso8601
    }
    update!(reviews: (reviews || []) + [ entry ])
    entry
  end

  def review_average
    approved = approved_reviews
    return 0.0 if approved.empty?

    (approved.sum { |review| review["rating"].to_i } / approved.size.to_f).round(1)
  end
end