---
tags:
  - hotel_cms
  - tasks
created: 2026-08-12
---

# Задачи

- [x] Добавить календарь бронирований в админку
- [x] Редиректы на предыдущую страницу после изменений
- [x] Настроить Obsidian vault для проекта
- [x] Открыть vault в Obsidian: «Open folder as vault» → `~/ai/projects/hotel_cms`
- [x] Аудит бизнес-логики и исправление багов (телефон гостя, maintenance/cleaning номера, фантомные user/guest, переходы статусов, guests_count, полиморфные отзывы, slug)
- [x] Рефакторинг: dry-monads (BookingCreator, RoomAvailability), концерны StatusTransitionable/StatusNotifiable, синхронизация статуса номера в модели
- [x] Exclusion constraint на брони (btree_gist) — защита от гонок
- [x] Unique index на отзывы (user, reviewable) + валидация
- [x] Валидация service_date не в прошлом
- [x] Полный CRUD галереи в админке (edit/update) + публичная страница `/gallery` с лайтбоксом

## Идеи на будущее

- [ ] Ограничение: услуга не может быть заказана без активной брони (сервисы привязаны к пребыванию)
