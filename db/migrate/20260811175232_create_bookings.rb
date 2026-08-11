class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :guest, null: false, foreign_key: true
      t.references :room, null: false, foreign_key: true
      t.date :check_in, null: false
      t.date :check_out, null: false
      t.string :status, null: false, default: "pending"
      t.decimal :total_price, precision: 12, scale: 2, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :bookings, [ :room_id, :check_in, :check_out ]
    add_index :bookings, :status
    add_index :bookings, :check_in
  end
end
