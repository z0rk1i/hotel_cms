FactoryBot.define do
  factory :room do
    sequence(:number) { |n| format("%03d", n + 100) }
    category { %w[Стандарт Комфорт Люкс].sample }
    floor { rand(1..5) }
    size_sqm { rand(15..50) }
    capacity { rand(1..4) }
    price_per_night { Faker::Commerce.price(range: 1000..8000).round(2) }
    weekend_multiplier { 1.2 }
    min_nights { 1 }
    status { "available" }
    description { Faker::Lorem.sentence }

    trait :maintenance do
      status { "maintenance" }
    end

    trait :cleaning do
      status { "cleaning" }
    end

    trait :unavailable do
      unavailable_from { Date.current - 2 }
      unavailable_until { Date.current + 5 }
    end

    trait :with_photos do
      after(:build) do |room|
        room.photos.attach(io: StringIO.new("fake image"), filename: "photo.jpg", content_type: "image/jpeg")
      end
    end
  end
end
