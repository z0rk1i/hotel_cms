FactoryBot.define do
  factory :page do
    sequence(:slug) { |n| "page-#{n}" }
    title { Faker::Lorem.sentence(word_count: 3) }
    body { Faker::Lorem.paragraph }
  end
end
