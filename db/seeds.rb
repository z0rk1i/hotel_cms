# Demo seed data for the Hotel CMS.
# Idempotent: safe to run multiple times. Usage: bin/rails db:seed

# --- Users ---
admin = User.find_or_initialize_by(email: "admin@example.com")
admin.role = :admin
admin.full_name = "Администратор"
admin.password = "password123"
admin.password_confirmation = "password123"
admin.save!

guest = User.find_or_initialize_by(phone: "+7 900 000-00-00")
guest.role = :guest
guest.full_name = "Иванов Иван"
guest.email = "guest@example.com"
guest.password = "password123"
guest.password_confirmation = "password123"
guest.save!

guests = [
  [ "Анна Смирнова", "+7 900 111-22-33", "anna@example.com" ],
  [ "Иван Петров", "+7 900 444-55-66", "ivan@example.com" ],
  [ "Мария Кузнецова", "+7 900 777-88-99", "maria@example.com" ],
  [ "Дмитрий Соколов", "+7 900 123-45-67", "dmitry@example.com" ]
]
guest_records = guests.map do |full_name, phone, email|
  User.find_or_create_by!(phone: phone) do |user|
    user.role = :guest
    user.full_name = full_name
    user.email = email
    user.password = "password123"
  end
end

# --- Rooms ---
categories = {
  "Стандарт" => 2_500,
  "Комфорт" => 3_500,
  "Люкс" => 6_000
}
amenities_by_category = {
  "Стандарт" => %w[Wi-Fi Телевизор],
  "Комфорт" => %w[Wi-Fi Телевизор Кондиционер Балкон],
  "Люкс" => %w[Wi-Fi Телевизор Кондиционер Балкон Мини-бар Сейф]
}
rooms_data = [
  [ "101", "Стандарт", 1, 18, 2 ], [ "102", "Стандарт", 1, 18, 2 ],
  [ "103", "Стандарт", 1, 20, 3 ], [ "201", "Комфорт", 2, 24, 2 ],
  [ "202", "Комфорт", 2, 24, 2 ], [ "203", "Комфорт", 2, 26, 3 ],
  [ "301", "Люкс", 3, 40, 4 ], [ "302", "Люкс", 3, 45, 4 ]
]
rooms_data.each do |number, category, floor, size, capacity|
  Room.find_or_create_by!(number: number) do |room|
    room.category = category
    room.floor = floor
    room.size_sqm = size
    room.capacity = capacity
    room.price_per_night = categories[category] + 200
    room.weekend_multiplier = 1.2
    room.min_nights = 1
    room.status = :available
    room.amenities = amenities_by_category[category]
    room.description = "#{category} на #{floor} этаже. #{capacity} гостя, #{size} м²."
  end
end

# --- Stays (over the next 10 days) ---
rooms = Room.order(:number).to_a
statuses = %w[pending confirmed checked_in checked_out cancelled]

30.times do |i|
  room = rooms.sample
  check_in = Date.current + rand(0..9)
  nights = rand(1..4)
  check_out = check_in + nights

  next if room.maintenance?
  next if room.unavailable_during?(check_in, check_out)
  next if room.overlapping_stays(check_in, check_out).exists?

  user = (guest_records + [ guest ]).sample
  status = statuses.sample
  Stay.find_or_create_by!(user: user, room: room, check_in: check_in, check_out: check_out) do |stay|
    stay.status = status
    stay.guests_count = rand(1..room.capacity)
    stay.notes = [ nil, "Просьба тихий номер", "Ранний заезд", "Дополнительная подушка" ].sample
  end.tap do |stay|
    next if stay.persisted? == false

    room.update_columns(status: "cleaning") if status == "checked_out" && room.status == "available"
  end
end

# --- Payments (current month, demo) ---
month_start = Date.current.beginning_of_month
payment_plans = [
  [ "cash", 1.0 ],
  [ "card", 0.5 ],
  [ "transfer", 0.8 ],
  [ "card", 1.0 ],
  [ "cash", 0.6 ]
]
payable_stays = Stay.where(status: %w[confirmed checked_in checked_out]).order(:id).to_a
payment_plans.each_with_index do |(method, ratio), i|
  stay = payable_stays[i] || payable_stays.sample
  next if stay.nil? || stay.payments.any? { |p| p["note"] == "Демо-оплата" }

  amount = (stay.total_price.to_f * ratio).round
  next if amount.zero?

  paid_at = [ month_start + (i * 2).days + 11.hours, Time.current ].min
  stay.add_payment!(method: method, amount: amount, paid_at: paid_at, note: "Демо-оплата")
  puts "Payment: №#{stay.id} #{stay.room.number} — #{method} #{amount} ₽"
end

# --- Monthly report ---
Report.refresh_month(Date.current)

puts "Seed complete. Admin: admin@example.com / password123"
