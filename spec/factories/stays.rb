FactoryBot.define do
  factory :stay do
    room
    user
    check_in { Date.current + 2 }
    check_out { Date.current + 4 }
    guests_count { 1 }
    status { "pending" }
    notes { nil }

    after(:build) do |stay|
      if stay.price_breakdown.blank? && stay.room && stay.check_in && stay.check_out
        stay.price_breakdown = (stay.check_in...stay.check_out).map do |date|
          { "date" => date.to_s, "amount" => stay.room.price_for_night(date) }
        end
      end
    end

    trait :confirmed do
      status { "confirmed" }
    end

    trait :checked_in do
      status { "checked_in" }
      check_in { Date.current - 1 }
      check_out { Date.current + 3 }
    end

    trait :checked_out do
      status { "checked_out" }
      check_in { Date.current - 10 }
      check_out { Date.current - 8 }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :with_payment do
      after(:create) do |stay|
        stay.add_payment!(method: "cash", amount: 1000, paid_at: Time.current)
      end
    end
  end
end
