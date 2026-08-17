# Hotel CMS

Специализированная CMS для управления гостиницей. Backend — Sinatra 4 (Rack), данные — ActiveRecord 8.1 и PostgreSQL.

## Возможности

### Публичный сайт отеля (`/`)

- **Витрина номеров** — карточки с фото, категориями и тарифами, страница номера с отзывами и свободными окнами
- **Поиск доступности** — фильтр по категории и удобствам, сортировка по цене, проверка свободных номеров на даты с учётом числа гостей
- **Бронирование** — публичная форма с проверкой пересечений и валидацией дат; если номер занят, виджет предлагает свободные альтернативы
- **Галерея, новости, страницы** — статический контент из YAML (`db/seeds/static/`), страница политики обработки ПДн
- **Личный кабинет** — просмотр своих броней по номеру телефона

### Админка (`/admin`)

- **Дашборд** — загрузка отеля, выручка за месяц, гости в отеле, заезды/выезды сегодня и предстоящие, последние брони
- **Номера** — CRUD: категория, этаж, вместимость, тариф (с коэффициентом выходных), статусы (свободен/занят/ремонт/уборка), загрузка и удаление фотографий
- **Бронирования** — CRUD, смена статусов (подтвердить / заселить / выселить / отменить), оплаты (cash/card/transfer) и услуги на карточке брони, автопересчёт цены с фиксацией снимка по ночам
- **Гости** — база с поиском по имени и телефону, фильтр VIP, карточка с историей броней, слияние дублей, отметка VIP
- **Отчёты** — по месяцам/периодам: план vs факт по ночам, занятые ночи, выручка по категориям; экспорт в CSV

## Стек

- Ruby 3.4.10, Sinatra 4 (Rack), PostgreSQL 14
- ActiveRecord 8.1 (вне Rails), BCrypt (аутентификация), Rack::Session + CSRF (`protect_from_forgery`), I18n
- HAML, Tailwind CSS (статический билд), vanilla JS (без Stimulus/Turbo)
- Фото номеров — файлы в `public/uploads/photos` (без Active Storage)
- RSpec + FactoryBot + Faker (128 тестов), RuboCop (rubocop-rails-omakase)

## Установка

```bash
# 1. Убедитесь, что Ruby 3.4.10 и PostgreSQL 14 запущены
rvm use 3.4.10
brew services start postgresql@14

# 2. Установка зависимостей
bundle install

# 3. База данных (схема из db/structure.sql, без миграций)
bundle exec rake db:schema_load
bundle exec rake db:seed   # демо-данные + админ

# 4. Запуск (монтирует /admin и / в config.ru)
bundle exec rackup -p 3100 -o 127.0.0.1
```

Откройте http://localhost:3100 — публичный сайт отеля.
Админка: http://localhost:3100/admin (логин `admin@example.com`, пароль `password123`).

> На машине разработчика Ruby установлен через rvm: перед командами `bundle` нужен `source hotel_cms_env.sh` (см. `notes/handbook.md`).

## Тесты

```bash
bundle exec rake db:test_prepare   # пересоздать тестовую БД из схемы
bundle exec rspec                  # 128 тестов
bundle exec rubocop                # стиль (0 offenses)
```

## Структура

```
app.rb                   — Sinatra-приложение публичного сайта (App)
admin.rb                 — Sinatra-приложение админки (AdminApp): register модулей маршрутов
app/app_base.rb          — AppBase < Sinatra::Base: общий конфиг, before-блок (flash+CSRF), 404/500, parse_date/slice_params
app/controllers/admin/   — маршруты админки по ресурсам (*_routes.rb, Sinatra-расширения)
app/models/              — Room, User, Stay, Report (+ RoomPhoto)
app/services/            — RoomSearch (фильтры/доступность), StaticContent (YAML), Reports::Builder
app/helpers/             — ApplicationHelper, AdminHelper, AppSupport, Routes
app/mailers/             — BookingMailer (письма гостю/админу, gem mail)
app/views/               — HAML-вьюхи (public_site/ + admin/)
app/assets/tailwind/     — исходник Tailwind (сборка в public/assets/tailwind.css)
public/assets/           — собранный JS/CSS
public/uploads/photos/   — фото номеров
config/environment.rb    — загрузка приложения (bundler, AR, I18n, модели, сервисы)
config/database.yml      — подключение БД
config.ru                — Rack-конфиг (map /admin → AdminApp, / → App)
db/structure.sql         — схема БД; db/seeds.rb + db/seeds/static/ — сиды
spec/                    — тесты (models, requests)
notes/                   — заметки проекта (Obsidian vault)
```