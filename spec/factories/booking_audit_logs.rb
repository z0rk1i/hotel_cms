FactoryBot.define do
  factory :booking_audit_log do
    booking
    to_status { "confirmed" }
    from_status { "pending" }
    administrator { nil }
  end
end
