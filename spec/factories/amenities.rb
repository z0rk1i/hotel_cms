FactoryBot.define do
  factory :amenity do
    sequence(:name) { |n| "Удобство #{n}" }
    icon { %w[star wifi air coffee parking elevator].sample }
  end
end
