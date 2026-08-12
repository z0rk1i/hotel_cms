FactoryBot.define do
  factory :closed_date do
    sequence(:date) { |n| Date.current + n }
    reason { nil }
  end
end
