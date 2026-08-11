# Hotel CMS

Специализированная CMS для управления гостиницей на Ruby on Rails.

## Возможности

- **Дашборд** — загрузка отеля, выручка за месяц, гости в отеле, предстоящие заезды
- **Номера** — категории, этажи, вместимость, тарифы, статусы (свободен/занят/ремонт/уборка), фотографии
- **Бронирования** — создание с автоматическим подбором свободных номеров на даты, проверка пересечений, смена статусов (подтвердить / заселить / выселить / отменить), авто-расчёт стоимости по числу ночей
- **Гости** — база гостей, контакты, поиск по имени и телефону, пагинация
- **Контент сайта** — динамические страницы, новости, услуги, галерея
- **Публичный сайт отеля** — витрина номеров, услуг, новостей и галереи для гостей
- **Админка** — вход по логину/паролю (Devise), защита всех разделов

## Стек

- Ruby 3.4.10, Rails 8.1, PostgreSQL 14
- Hotwire (Turbo + Stimulus), Tailwind CSS
- Devise (аутентификация), Active Storage (загрузка файлов)
- RSpec + FactoryBot + Faker (тесты), RuboCop (стиль)

## Установка

```bash
# 1. Убедитесь, что Ruby 3.4.10 и PostgreSQL запущены
rvm use 3.4.10
brew services start postgresql@14

# 2. Установка зависимостей
bundle install

# 3. База данных
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed   # демо-данные + админ

# 4. Запуск
bin/rails server
```

Откройте http://localhost:3000 — публичный сайт отеля.
Админка: http://localhost:3000/admin (логин `admin@example.com`, пароль `password123`).

## Тесты

```bash
bin/rails db:test:prepare
bundle exec rspec
```

## Структура

```
app/controllers/admin/   — контроллеры админки
app/models/              — Room, RoomCategory, Guest, Booking, Page, News, Service, GalleryImage
app/views/admin/         — вьюхи админки
app/views/public_site/   — публичный сайт
spec/models/             — тесты моделей
spec/requests/           — request-спеки (авторизация, брони, JSON-эндпоинты)
db/seeds.rb              — демо-данные
```
