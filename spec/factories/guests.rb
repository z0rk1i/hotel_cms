FactoryBot.define do
  factory :guest do
    full_name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    phone { Faker::PhoneNumber.cell_phone }
    passport_number { Faker::Number.unique.number(digits: 10).to_s }
    notes { nil }
  end
end
