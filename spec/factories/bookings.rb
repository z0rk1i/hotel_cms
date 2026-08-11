FactoryBot.define do
  factory :booking do
    guest
    room
    check_in { Date.current + 3 }
    check_out { Date.current + 5 }
    status { :pending }
    guests_count { 1 }
    notes { nil }

    trait :confirmed do
      status { :confirmed }
    end

    trait :checked_in do
      status { :checked_in }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :checked_out do
      status { :checked_out }
    end
  end
end
