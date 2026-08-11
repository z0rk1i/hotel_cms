FactoryBot.define do
  factory :user do
    full_name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    phone { Faker::PhoneNumber.cell_phone }
    password { "password123" }
    password_confirmation { "password123" }

    trait :vkontakte do
      email { "vkontakte-123@example.com" }
      provider { "vkontakte" }
      uid { "123456" }
    end

    trait :yandex do
      email { "yandex-456@example.com" }
      provider { "yandex" }
      uid { "456789" }
    end
  end
end
