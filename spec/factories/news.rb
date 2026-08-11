FactoryBot.define do
  factory :news do
    title { Faker::Lorem.sentence(word_count: 4) }
    body { Faker::Lorem.paragraph }
    published_at { Time.current }
  end
end
