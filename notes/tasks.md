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

## Идеи на будущее

- [ ] DB-ограничение на непересечение броней (exclusion constraint) — защита от гонок
- [ ] `service_date` не в прошлом для заказов услуг
- [ ] Запрет повторных отзывов на один объект от одного пользователя
