# Demo seed data for the Hotel CMS.
# Idempotent: safe to run multiple times. Usage: bin/rails db:seed

# --- Administrator ---
Administrator.find_or_create_by!(email: "admin@example.com") do |admin|
  admin.password = "password123"
  admin.password_confirmation = "password123"
end

# --- Public user (guest account) ---
User.find_or_create_by!(email: "guest@example.com") do |user|
  user.full_name = "Иванов Иван"
  user.phone = "+7 900 000-00-00"
  user.password = "password123"
  user.password_confirmation = "password123"
end

# --- Room categories ---
categories = [
  { name: "Стандарт", base_price: 2_500, description: "Уютный номер 18 м² с двуспальной кроватью, рабочим столом и Wi-Fi." },
  { name: "Комфорт", base_price: 3_500, description: "Номер 24 м² с балконом и видом на парк. Кофемашина в номере." },
  { name: "Люкс", base_price: 6_000, description: "Просторный номер 40 м² с гостиной зоной, джакузи и панорамными окнами." }
]
room_categories = categories.map do |attrs|
  RoomCategory.find_or_create_by!(name: attrs[:name]) { |c| c.assign_attributes(attrs) }
end

# --- Rooms ---
rooms_data = [
  [ "101", room_categories[0], 1, 18, 2 ], [ "102", room_categories[0], 1, 18, 2 ],
  [ "103", room_categories[0], 1, 20, 3 ], [ "201", room_categories[1], 2, 24, 2 ],
  [ "202", room_categories[1], 2, 24, 2 ], [ "203", room_categories[1], 2, 26, 3 ],
  [ "301", room_categories[2], 3, 40, 4 ], [ "302", room_categories[2], 3, 45, 4 ]
]
rooms_data.each do |number, category, floor, size, capacity|
  Room.find_or_create_by!(number: number) do |room|
    room.category = category
    room.floor = floor
    room.size_sqm = size
    room.capacity = capacity
    room.price_per_night = category.base_price + 200
    room.weekend_multiplier = 1.2
    room.status = :available
    room.description = "#{category.name} на #{floor} этаже. #{capacity} гостя, #{size} м²."
  end
end

# --- Price periods (dynamic pricing) ---
current_year = Date.current.year
price_periods = [
  { name: "Высокий сезон", starts_on: Date.new(current_year, 7, 1), ends_on: Date.new(current_year, 8, 31), multiplier: 1.3 },
  { name: "Новогодние праздники", starts_on: Date.new(current_year, 12, 25), ends_on: Date.new(current_year + 1, 1, 10), multiplier: 1.5 }
]
price_periods.each do |attrs|
  PricePeriod.find_or_create_by!(name: attrs[:name]) { |period| period.assign_attributes(attrs.except(:name)) }
end

# --- Amenities ---
amenities = {
  "Wi-Fi" => "wifi",
  "Завтрак" => "coffee",
  "Кондиционер" => "air",
  "Балкон" => "balcony",
  "Вид на парк" => "tree",
  "Телевизор" => "tv",
  "Мини-бар" => "fridge",
  "Сейф" => "lock"
}
amenity_records = amenities.map do |name, icon|
  Amenity.find_or_create_by!(name: name) { |a| a.icon = icon }
end
Room.order(:number).each_with_index do |room, i|
  count = [ 3, 4, 5, 6 ].sample
  room.amenities = amenity_records.sample(count) if room.amenities.empty?
end

# --- Room photos (Lorem Picsum, deterministic per room) ---
require "open-uri"

room_photo_scenes = [ [ "bedroom", 800, 600 ], [ "desk", 800, 600 ], [ "bath", 800, 600 ], [ "view", 1024, 768 ] ]
rooms_with_photos = 0

Room.order(:number).each do |room|
  next if room.photos.any?

  room_photo_scenes.each do |scene, width, height|
    url = "https://picsum.photos/seed/hotel-#{room.number}-#{scene}/#{width}/#{height}"
    begin
      room.photos.attach(io: URI.open(url), filename: "#{room.number}-#{scene}.jpg", content_type: "image/jpeg")
    rescue OpenURI::HTTPError, SocketError, Errno::ECONNREFUSED, Timeout::Error, URI::InvalidURIError
      warn "Не удалось загрузить фото номера: #{url}"
    end
  end
  rooms_with_photos += 1 if room.photos.any?
end
puts "Attached photos to #{rooms_with_photos} rooms."

# --- Guests ---
guests = [
  [ "Анна Смирнова", "+7 900 111-22-33", "anna@example.com" ],
  [ "Иван Петров", "+7 900 444-55-66", "ivan@example.com" ],
  [ "Мария Кузнецова", "+7 900 777-88-99", "maria@example.com" ],
  [ "Дмитрий Соколов", "+7 900 123-45-67", "dmitry@example.com" ]
]
guest_records = guests.map do |full_name, phone, email|
  Guest.find_or_create_by!(full_name: full_name) { |g| g.phone = phone; g.email = email }
end

# --- Bookings (over the next 10 days) ---
rooms = Room.order(:number).to_a
statuses = %i[pending confirmed checked_in checked_out cancelled]

30.times do |i|
  room = rooms.sample
  check_in = Date.current + rand(0..9)
  nights = rand(1..4)
  check_out = check_in + nights

  next if Booking.active_overlapping(check_in, check_out).where(room_id: room.id).exists?

  Booking.find_or_create_by!(
    guest_id: guest_records.sample.id,
    room_id: room.id,
    check_in: check_in,
    check_out: check_out
  ) do |booking|
    booking.status = statuses.sample
    booking.guests_count = rand(1..room.capacity)
    booking.notes = [ nil, "Просьба тихий номер", "Ранний заезд", "Дополнительная подушка" ].sample
  end
end

# --- Content ---
Page.find_or_create_by!(slug: "about") do |page|
  page.title = "О гостинице"
  page.body = "Наша гостиница расположена в историческом центре города. " \
              "К услугам гостей — 8 уютных номеров, ресторан с завтраками и спа-центр.\n\n" \
              "Мы дорожим репутацией и делаем всё, чтобы ваш отдых был комфортным."
end
Page.find_or_create_by!(slug: "contacts") do |page|
  page.title = "Контакты"
  page.body = "Адрес: г. Москва, ул. Примерная, д. 1\n" \
              "Телефон: +7 (900) 000-00-00\n" \
              "Email: hello@hotel.example\n" \
              "Ресепшн работает круглосуточно."
end

News.find_or_create_by!(title: "Открытие нового спа-центра") do |news|
  news.body = "Приглашаем гостей в обновлённый спа-центр: сауна, массажный кабинет и бассейн. " \
              "Для гостей отеля — скидка 20% на первую процедуру."
  news.published_at = Time.current
end
News.find_or_create_by!(title: "Спецпредложение на выходные") do |news|
  news.body = "При бронировании от 2 ночей на выходные — скидка 15%. Промокод WEEKEND при заезде."
  news.published_at = Time.current
end

Service.find_or_create_by!(name: "Завтрак «шведский стол»") do |service|
  service.price = 500
  service.description = "Ежедневно с 7:00 до 11:00."
end
Service.find_or_create_by!(name: "Трансфер из аэропорта") do |service|
  service.price = 1_500
  service.description = "Комфортабельный автомобиль, встреча с табличкой."
end
Service.find_or_create_by!(name: "Прачечная") do |service|
  service.price = 300
  service.description = "Стирка и глажка в течение 24 часов."
end
Service.find_or_create_by!(name: "Wi-Fi") do |service|
  service.price = 0
  service.description = "Бесплатный высокоскоростной интернет во всех номерах."
end

puts "Seed complete. Admin: admin@example.com / password123"
