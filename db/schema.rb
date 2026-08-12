# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_12_183910) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gist"
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "administrators", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_administrators_on_email", unique: true
    t.index ["reset_password_token"], name: "index_administrators_on_reset_password_token", unique: true
  end

  create_table "amenities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "icon", default: "star", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "booking_audit_logs", force: :cascade do |t|
    t.bigint "administrator_id"
    t.bigint "booking_id", null: false
    t.datetime "created_at", null: false
    t.string "from_status"
    t.string "to_status", null: false
    t.datetime "updated_at", null: false
    t.index ["administrator_id"], name: "index_booking_audit_logs_on_administrator_id"
    t.index ["booking_id"], name: "index_booking_audit_logs_on_booking_id"
  end

  create_table "booking_nightly_prices", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.bigint "booking_id", null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id", "date"], name: "index_booking_nightly_prices_on_booking_id_and_date", unique: true
    t.index ["booking_id"], name: "index_booking_nightly_prices_on_booking_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.date "check_in", null: false
    t.date "check_out", null: false
    t.datetime "created_at", null: false
    t.bigint "guest_id", null: false
    t.integer "guests_count", default: 1, null: false
    t.text "notes"
    t.date "price_frozen_on"
    t.bigint "room_id", null: false
    t.string "status", default: "pending", null: false
    t.decimal "total_price", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["check_in"], name: "index_bookings_on_check_in"
    t.index ["guest_id"], name: "index_bookings_on_guest_id"
    t.index ["room_id", "check_in", "check_out"], name: "index_bookings_on_room_id_and_check_in_and_check_out"
    t.index ["room_id"], name: "index_bookings_on_room_id"
    t.index ["status"], name: "index_bookings_on_status"
    t.index ["user_id"], name: "index_bookings_on_user_id"
    t.exclusion_constraint "room_id WITH =, daterange(check_in, check_out) WITH &&", where: "(status)::text <> 'cancelled'::text", using: :gist, name: "no_overlapping_bookings"
  end

  create_table "closed_dates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "reason"
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_closed_dates_on_date", unique: true
  end

  create_table "consent_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "guest_id", null: false
    t.datetime "signed_at", null: false
    t.datetime "updated_at", null: false
    t.index ["guest_id"], name: "index_consent_logs_on_guest_id"
    t.index ["signed_at"], name: "index_consent_logs_on_signed_at"
  end

  create_table "gallery_images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "guests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "full_name", null: false
    t.boolean "is_vip", default: false, null: false
    t.text "notes"
    t.string "passport_number"
    t.string "phone"
    t.string "preferences"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_guests_on_email"
    t.index ["phone"], name: "index_guests_on_phone"
  end

  create_table "news", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "published_at"
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["published_at"], name: "index_news_on_published_at"
    t.index ["slug"], name: "index_news_on_slug", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "kind"
    t.bigint "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.datetime "read_at"
    t.string "title", null: false
    t.boolean "to_admin", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["to_admin", "read_at"], name: "index_notifications_on_to_admin_and_read_at"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "pages", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_pages_on_slug", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.bigint "booking_id", null: false
    t.datetime "created_at", null: false
    t.string "method", default: "cash", null: false
    t.text "note"
    t.datetime "paid_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id", "paid_at"], name: "index_payments_on_booking_id_and_paid_at"
    t.index ["booking_id"], name: "index_payments_on_booking_id"
    t.index ["paid_at"], name: "index_payments_on_paid_at"
  end

  create_table "price_periods", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "ends_on", null: false
    t.integer "min_nights"
    t.decimal "multiplier", precision: 5, scale: 2, default: "1.0", null: false
    t.string "name", null: false
    t.date "starts_on", null: false
    t.datetime "updated_at", null: false
    t.index ["starts_on", "ends_on"], name: "index_price_periods_on_starts_on_and_ends_on"
  end

  create_table "ratelimit_counters", force: :cascade do |t|
    t.string "classification", null: false
    t.integer "count", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "epoch", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "classification", "epoch"], name: "index_ratelimit_counters_unique", unique: true
  end

  create_table "reviews", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "rating", null: false
    t.bigint "reviewable_id", null: false
    t.string "reviewable_type", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["reviewable_type", "reviewable_id", "status"], name: "index_reviews_on_reviewable_type_and_reviewable_id_and_status"
    t.index ["reviewable_type", "reviewable_id"], name: "index_reviews_on_reviewable"
    t.index ["user_id", "reviewable_type", "reviewable_id"], name: "index_reviews_on_user_reviewable_unique", unique: true
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "room_amenities", force: :cascade do |t|
    t.bigint "amenity_id", null: false
    t.datetime "created_at", null: false
    t.bigint "room_id", null: false
    t.datetime "updated_at", null: false
    t.index ["amenity_id"], name: "index_room_amenities_on_amenity_id"
    t.index ["room_id", "amenity_id"], name: "index_room_amenities_on_room_id_and_amenity_id", unique: true
    t.index ["room_id"], name: "index_room_amenities_on_room_id"
  end

  create_table "room_categories", force: :cascade do |t|
    t.decimal "base_price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "room_status_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "from_status", null: false
    t.bigint "room_id", null: false
    t.string "to_status", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id"], name: "index_room_status_logs_on_room_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.integer "capacity", default: 1, null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "floor", default: 1, null: false
    t.string "number", null: false
    t.decimal "price_per_night", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "size_sqm"
    t.string "status", default: "available", null: false
    t.date "unavailable_from"
    t.date "unavailable_until"
    t.datetime "updated_at", null: false
    t.decimal "weekend_multiplier", precision: 5, scale: 2, default: "1.0", null: false
    t.index ["category_id"], name: "index_rooms_on_category_id"
    t.index ["number"], name: "index_rooms_on_number", unique: true
    t.index ["status"], name: "index_rooms_on_status"
  end

  create_table "service_orders", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.datetime "created_at", null: false
    t.text "notes"
    t.integer "quantity", default: 1, null: false
    t.date "service_date", null: false
    t.bigint "service_id", null: false
    t.string "status", default: "pending", null: false
    t.decimal "total_price", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["booking_id"], name: "index_service_orders_on_booking_id"
    t.index ["service_date"], name: "index_service_orders_on_service_date"
    t.index ["service_id"], name: "index_service_orders_on_service_id"
    t.index ["user_id", "status"], name: "index_service_orders_on_user_id_and_status"
    t.index ["user_id"], name: "index_service_orders_on_user_id"
  end

  create_table "services", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "full_name"
    t.string "phone"
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "booking_audit_logs", "administrators"
  add_foreign_key "booking_audit_logs", "bookings"
  add_foreign_key "booking_nightly_prices", "bookings"
  add_foreign_key "bookings", "guests"
  add_foreign_key "bookings", "rooms"
  add_foreign_key "bookings", "users"
  add_foreign_key "consent_logs", "guests"
  add_foreign_key "notifications", "users"
  add_foreign_key "payments", "bookings"
  add_foreign_key "reviews", "users"
  add_foreign_key "room_amenities", "amenities"
  add_foreign_key "room_amenities", "rooms"
  add_foreign_key "room_status_logs", "rooms"
  add_foreign_key "rooms", "room_categories", column: "category_id"
  add_foreign_key "service_orders", "bookings"
  add_foreign_key "service_orders", "services"
  add_foreign_key "service_orders", "users"
end
