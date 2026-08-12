---
tags:
  - hotel_cms
  - handbook
created: 2026-08-12
---

# Хендбук проекта

## Стек

- Ruby 3.4.10, Rails 8.1, PostgreSQL 14
- Hotwire (Turbo + Stimulus), Tailwind CSS
- Devise (аутентификация), Active Storage
- RSpec + FactoryBot + Faker, RuboCop

## Команды

```bash
source /Users/z0rk1/ai/projects/hotel_cms_env.sh   # GEM_HOME/PATH для этой машины
bin/rails server                                    # запуск (http://localhost:3000)
bin/rails db:seed                                   # демо-данные
bundle exec rspec                                   # тесты
bundle exec rubocop                                 # стиль
```

## Доступы

- Админка: `/admin` (логин `admin@example.com`, пароль `password123`)
- Публичный сайт отеля: `/`

## Структура

- `app/controllers/admin/` — контроллеры админки
- `app/models/` — Room, RoomCategory, Guest, Booking, Page, News, Service, GalleryImage
- `app/views/admin/` — вьюхи админки
- `app/views/public_site/` — публичный сайт
- `spec/` — тесты (models, requests)
- `notes/` — заметки проекта (Obsidian)

## Нюансы

- На этой машине Ruby установлен через rvm; перед командами `bundle` нужен `source hotel_cms_env.sh`.
- Статусы броней: `pending / confirmed / checked_in / checked_out / cancelled`.
- Успешные мутации в админке редиректят на предыдущую страницу (не на index).
