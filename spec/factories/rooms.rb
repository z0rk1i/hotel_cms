FactoryBot.define do
  factory :room do
    association :category, factory: :room_category
    sequence(:number) { |n| format("%03d", n + 100) }
    floor { rand(1..5) }
    size_sqm { rand(15..50) }
    capacity { rand(1..4) }
    price_per_night { Faker::Commerce.price(range: 1000..8000).round(2) }
    status { :available }
    description { Faker::Lorem.sentence }
  end
end
