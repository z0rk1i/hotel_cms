class RebuildHotelCmsToThreeModels < ActiveRecord::Migration[8.1]
  def change
    enable_extension "btree_gist"

    create_table :rooms do |t|
      t.string :number, null: false
      t.string :category, null: false, default: "Стандарт"
      t.integer :floor, null: false
      t.integer :capacity, null: false
      t.integer :size_sqm
      t.text :description
      t.decimal :price_per_night, precision: 10, scale: 2, null: false
      t.decimal :weekend_multiplier, precision: 4, scale: 2, null: false, default: 1.0
      t.integer :min_nights, null: false, default: 1
      t.string :status, null: false, default: "available"
      t.jsonb :amenities, null: false, default: []
      t.jsonb :reviews, null: false, default: []
      t.date :unavailable_from
      t.date :unavailable_until
      t.timestamps
    end
    add_index :rooms, :number, unique: true
    add_index :rooms, :status
    add_index :rooms, :category

    create_table :users do |t|
      t.string :role, null: false, default: "guest"
      t.string :full_name
      t.string :phone
      t.string :passport_number
      t.boolean :is_vip, null: false, default: false
      t.text :preferences
      t.text :notes
      t.datetime :consent_signed_at
      t.string :email, default: ""
      t.string :encrypted_password, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :role

    create_table :stays do |t|
      t.references :room, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :check_in, null: false
      t.date :check_out, null: false
      t.integer :guests_count, null: false, default: 1
      t.string :status, null: false, default: "pending"
      t.decimal :total_price, precision: 12, scale: 2, null: false, default: 0
      t.date :price_frozen_on
      t.jsonb :price_breakdown, null: false, default: []
      t.jsonb :payments, null: false, default: []
      t.jsonb :services, null: false, default: []
      t.text :notes
      t.timestamps
    end
    add_index :stays, :status
    add_index :stays, [ :room_id, :check_in ]

    execute <<~SQL.squish
      ALTER TABLE stays ADD CONSTRAINT no_overlapping_stays
      EXCLUDE USING gist (
        room_id WITH =,
        daterange(check_in, check_out, '[)') WITH &&
      ) WHERE (status <> 'cancelled')
    SQL

    create_table :reports do |t|
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.string :kind, null: false, default: "custom"
      t.jsonb :data, null: false, default: {}
      t.timestamps
    end
    add_index :reports, [ :kind, :period_start, :period_end ], unique: true

    create_table :active_storage_blobs do |t|
      t.string :key, null: false
      t.string :filename, null: false
      t.string :content_type
      t.text :metadata
      t.string :service_name, null: false
      t.bigint :byte_size, null: false
      t.string :checksum
      t.datetime :created_at, null: false
      t.index [ :key ], unique: true
    end

    create_table :active_storage_attachments do |t|
      t.string :name, null: false
      t.string :record_type, null: false
      t.bigint :record_id, null: false
      t.bigint :blob_id, null: false
      t.datetime :created_at, null: false
      t.index [ :record_type, :record_id, :name, :blob_id ],
              name: "index_active_storage_attachments_uniqueness", unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end

    create_table :active_storage_variant_records do |t|
      t.bigint :blob_id, null: false
      t.string :variation_digest, null: false
      t.datetime :created_at, null: false
      t.index [ :blob_id, :variation_digest ], unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
  end
end
