FactoryBot.define do
  factory :service do
    name { Faker::Commerce.product_name }
    description { Faker::Lorem.sentence }
    price { Faker::Commerce.price(range: 0..5000).round(2) }
  end
end
