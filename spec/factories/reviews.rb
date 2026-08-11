FactoryBot.define do
  factory :review do
    reviewable { association(:room) }
    user
    rating { rand(1..5) }
    body { Faker::Lorem.paragraph(sentence_count: 3) }
    status { :pending }

    trait :approved do
      status { :approved }
    end

    trait :rejected do
      status { :rejected }
    end
  end
end
