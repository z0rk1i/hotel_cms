FactoryBot.define do
  factory :room_category do
    sequence(:name) { |n| "Category #{n}" }
    description { Faker::Lorem.sentence }
    base_price { Faker::Commerce.price(range: 1000..8000).round(2) }
  end
end
