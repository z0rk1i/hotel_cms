FactoryBot.define do
  factory :notification do
    user
    notifiable { association(:booking) }
    kind { "booking_status" }
    title { "Статус брони изменён" }
    body { "Бронь — подтверждена." }
    read_at { nil }
  end
end
