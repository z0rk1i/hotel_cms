module Reports
  class Builder
    def self.build(from:, to:)
      new(from: from, to: to).build
    end

    def initialize(from:, to:)
      @from = from
      @to = to
    end

    def build
      stays = relevant_stays
      {
        "plan_revenue" => plan_revenue(stays),
        "fact_revenue" => fact_revenue(stays),
        "monthly_booked_revenue" => monthly_booked_revenue,
        "occupancy_rate" => occupancy_rate(stays),
        "booked_nights" => booked_nights(stays),
        "capacity_nights" => capacity_nights,
        "by_category" => by_category(stays),
        "nights" => nightly_plan(stays)
      }
    end

    private

    attr_reader :from, :to

    def nights
      (from...to).to_a
    end

    def relevant_stays
      Stay.where(status: %w[confirmed checked_in checked_out])
          .overlapping_period(from, to)
          .includes(:room)
    end

    def clipped_range(stay)
      [ from, stay.check_in ].max...[ to, stay.check_out ].min
    end

    def amount_on(date, breakdown)
      entry = breakdown.find { |row| row["date"] == date.to_s }
      entry ? entry["amount"].to_f : 0.0
    end

    def plan_revenue(stays)
      stays.sum do |stay|
        clipped_range(stay).sum { |date| amount_on(date, stay.price_breakdown) }
      end
    end

    def fact_revenue(stays)
      stays.sum do |stay|
        payments_in_period(stay).sum { |payment| payment["amount"].to_f }
      end
    end

    def monthly_booked_revenue
      Stay.checked_out.where("check_out BETWEEN ? AND ?", from, to).sum(:total_price)
    end

    def booked_nights(stays)
      stays.sum { |stay| clipped_range(stay).size }
    end

    def capacity_nights
      Room.count * nights.size
    end

    def occupancy_rate(stays)
      return 0.0 if capacity_nights.zero?

      (booked_nights(stays).to_f / capacity_nights).round(4)
    end

    def by_category(stays)
      stays.each_with_object({}) do |stay, result|
        category = stay.room.category
        result[category] ||= { "nights" => 0, "plan" => 0.0, "fact" => 0.0 }
        result[category]["nights"] += clipped_range(stay).size
        clipped_range(stay).each do |date|
          result[category]["plan"] += amount_on(date, stay.price_breakdown)
        end
        result[category]["fact"] += payments_in_period(stay).sum { |payment| payment["amount"].to_f }
      end
    end

    def nightly_plan(stays)
      result = nights.to_h { |date| [ date.to_s, { "plan" => 0.0, "fact" => 0.0 } ] }
      stays.each do |stay|
        clipped_range(stay).each do |date|
          node = result[date.to_s]
          next if node.nil?

          node["plan"] += amount_on(date, stay.price_breakdown)
          node["fact"] += payment_amount_on_day(stay, date)
        end
      end
      result
    end

    def payments_in_period(stay)
      stay.payments.select do |payment|
        Time.zone.parse(payment["paid_at"]).to_date.between?(from, to)
      end
    end

    def payment_amount_on_day(stay, date)
      stay.payments.sum do |payment|
        Time.zone.parse(payment["paid_at"]).to_date == date ? payment["amount"].to_f : 0.0
      end
    end
  end
end