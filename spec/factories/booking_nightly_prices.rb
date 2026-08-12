FactoryBot.define do
  factory :booking_nightly_price do
    booking
    date { booking.check_in }
    amount { 1000 }
  end
end
