FactoryBot.define do
  factory :consent_log do
    guest
    signed_at { Time.current }
  end
end
