FactoryBot.define do
  factory :service_order do
    transient do
      with_booking { true }
    end

    service
    user { create(:user) }
    service_date { Date.current + 3 }
    quantity { 1 }
    status { :pending }
    notes { nil }

    after(:build) do |order, evaluator|
      next unless evaluator.with_booking

      service_date = order.service_date || (Date.current + 3)
      order.booking ||= create(:booking, :confirmed, user: order.user,
                               check_in: service_date - 1,
                               check_out: service_date + 1)
    end

    trait :confirmed do
      status { :confirmed }
    end

    trait :cancelled do
      status { :cancelled }
    end
  end
end
