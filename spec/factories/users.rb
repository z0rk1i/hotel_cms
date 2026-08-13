FactoryBot.define do
  factory :user do
    full_name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    sequence(:phone) { |n| format("+7 900 000-%04d", n % 10_000) }
    password { "password123" }
    password_confirmation { "password123" }
    role { "guest" }

    trait :admin do
      role { "admin" }
    end

    trait :vip do
      is_vip { true }
    end

    trait :with_consent do
      consent_signed_at { Time.current }
    end

    trait :with_passport do
      passport_number { format("45 %05d", rand(99_999)) }
    end
  end
end
