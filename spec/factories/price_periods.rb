FactoryBot.define do
  factory :price_period do
    name { "Высокий сезон" }
    starts_on { Date.current }
    ends_on { Date.current + 30 }
    multiplier { 1.2 }
  end
end
