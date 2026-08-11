FactoryBot.define do
  factory :service_order do
    service
    user
    service_date { Date.current + 3 }
    quantity { 1 }
    status { :pending }
    notes { nil }

    trait :confirmed do
      status { :confirmed }
    end

    trait :cancelled do
      status { :cancelled }
    end
  end
end
