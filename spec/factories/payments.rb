FactoryBot.define do
  factory :payment do
    booking
    amount { 1000 }
    add_attribute(:method) { "cash" }
    paid_at { Time.current }
    note { nil }
  end
end
