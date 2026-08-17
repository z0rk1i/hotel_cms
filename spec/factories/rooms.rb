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
      after(:create) do |room|
        room.photos.create!(filename: "photo_#{SecureRandom.hex(4)}.jpg", thumb_filename: "thumb.jpg", position: 1)
      end
    end
  end
end
