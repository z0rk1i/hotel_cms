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
- [x] Услуги привязаны к активной брони: booking_id в service_orders, валидация (confirmed/checked_in + дата в периоде), отмена pending-заказов при отмене брони
- [x] Удобства номеров (Amenity + RoomAmenity): CRUD в админке, чекбоксы в форме номера, бейджики на карточках и странице номера, фильтр по удобствам на главной
- [x] Альтернативные номера при проверке доступности: если номер занят на даты, виджет предлагает свободные номера карточками-ссылками на бронь с подставленными датами
- [x] Демо-фото номеров в seeds: 4 фото на номер с Lorem Picsum (детерминированные), идемпотентно, без сети не ломаются
- [x] Отзывы только после проживания/заказа услуги (Room: checked_in/checked_out, Service: confirmed service_order)
- [x] Запрет бронирования прошлых дат на публичной форме (в BookingCreator, админ может вносить прошедшие брони)
- [x] Запрет maintenance/cleaning, пока в номере гости (confirmed/checked_in на сегодня)
- [x] Email админу о новых бронях и новых отзывах (AdminMailer, только если есть администраторы)
- [x] N+1: дашборд (upcoming_check_ins → includes guest/room), публичный сайт (amenities на главной и странице номера)
- [x] total_price не перезаписывается при несвязанных правках (только при смене дат/номера/создании)
- [x] Удалён неиспользуемый hello_controller.js
- [x] Экспорт бронирований и гостей в CSV из админки (с учётом фильтров статуса и поиска)
- [x] Ценовые периоды и коэффициент выходных: NightlyPricing по ночам, CRUD `/admin/price_periods`, поле weekend_multiplier у номера, разбивка по ночам на странице брони (351 тест)
- [x] Рефакторинг: shared_examples «admin CRUD resource» для CRUD-спек, концерны Booking (pricing/room-sync/audit/notifier), базовый `Admin::CrudController`, группировка номеров по категориям в контроллере главной (385 тестов)
- [x] dry-rb консолидация, фазы 0–1: characterization-спек `room_availability_spec.rb` (13 тестов), де-дуп парсинга дат через `DateParams.parse` (3 места) — 404 теста зелёные, rubocop 0
- [x] dry-rb консолидация, фазы 2–3: фикс silent `200 []` на available_rooms/admin available (`Failure` дат = 422 + error JSON, пустой search = `200 []`), коллапс unpacking Result в BookingsController#create → `result.value_or(result.failure)`
- [x] Оплаты по брони: модель `Payment` (amount, method cash/card/transfer, paid_at, note), CRUD в админке на карточке брони, колонка «Оплачено» в списке, баланс paid/due, выручка дашборда — реальные оплаты за месяц + «по тарифу», колонки «Оплачено/Долг» в CSV
- [x] Снимок цены: ночная раскладка в `booking_nightly_prices` (unique [booking_id, date]), `price_frozen_on` на брони, разбивка на странице — из снимка с пометкой «цена зафиксирована по тарифу» (426 тестов, rubocop 0)
- [ ] Инструментальные сервисы публичного сайта на dry-monads (`room_availability_controller.js` уже guard-ит range — только спека)

## Идеи на будущее

- [ ] _(пусто — идея «услуги без активной брони» реализована)_
- [ ] Дорожная карта доработок — [[improvements|плана улучшений]] (оплаты, снимок цены, closed dates, карточка гостя, 152-ФЗ, админ-уведомления, уборка, отчёты)
