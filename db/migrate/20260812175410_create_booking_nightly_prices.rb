class CreateBookingNightlyPrices < ActiveRecord::Migration[8.1]
  def change
    create_table :booking_nightly_prices do |t|
      t.references :booking, null: false, foreign_key: true
      t.date :date, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false

      t.timestamps
    end

    add_index :booking_nightly_prices, [ :booking_id, :date ], unique: true
  end
end
