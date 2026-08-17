---
tags:
  - hotel_cms
  - handbook
created: 2026-08-12
---

# Хендбук проекта

## Стек

- Ruby 3.4.10, Sinatra 4 (Rack), PostgreSQL 14
- ActiveRecord 8.1 (вне Rails), BCrypt (аутентификация), I18n
- HAML, Tailwind CSS (статический билд через Rakefile)
- RSpec + FactoryBot + Faker, RuboCop (rubocop-rails-omakase)

## Команды

```bash
source /Users/z0rk1/ai/projects/hotel_cms_env.sh   # GEM_HOME/PATH для этой машины
bundle exec rackup -p 3100 -o 127.0.0.1            # запуск (http://localhost:3100)
bundle exec rake db:seed                           # демо-данные
bundle exec rake db:schema_load                    # схема из db/structure.sql
bundle exec rake tailwind:build                    # пересобрать Tailwind CSS
bundle exec rspec                                  # тесты
bundle exec rubocop                                # стиль
```

## Доступы

- Админка: `/admin` (логин `admin@example.com`, пароль `password123`)
- Публичный сайт отеля: `/`

## Структура

- `app.rb` — Sinatra-приложение публичного сайта (монтируется на `/` в `config.ru`)
- `admin.rb` — Sinatra-приложение админки (монтируется на `/admin`)
- `config/environment.rb` — загрузка приложения (bundler, AR, I18n, модели, сервисы)
- `config/database.rb` — подключение БД из `config/database.yml`
- `config/mail.rb` — SMTP-настройки (письма BookingMailer)
- `app/models/` — Room, User, Stay, Report (+ RoomPhoto)
- `app/services/` — StaticContent, Reports::Builder
- `app/helpers/` — ApplicationHelper, AdminHelper, AppSupport, Routes
- `app/mailers/booking_mailer.rb` — письма гостю/админу (gem `mail`, без Rails)
- `app/views/` — HAML-вьюхи (public + admin)
- `public/assets/` — собранный JS/CSS (vanilla JS, без Stimulus/Turbo)
- `public/uploads/photos/` — фото номеров (замена Active Storage)
- `db/structure.sql` — схема БД; `db/seeds.rb` + `db/seeds/static/` — сиды
- `spec/` — тесты (128: models, requests)
- `notes/` — заметки проекта (Obsidian)

## Нюансы

- На этой машине Ruby установлен через rvm; перед командами `bundle` нужен `source hotel_cms_env.sh`.
- Время: `Time.zone_default` (не `Time.zone=`) — иначе puma-воркеры видят nil-зону и 500 в отчётах.
- Статусы броней: `pending / confirmed / checked_in / checked_out / cancelled`.
- Успешные мутации в админке редиректят на предыдущую страницу (не на index).
- Dev-сервер после работы останавливать (не оставлять фоновые процессы).