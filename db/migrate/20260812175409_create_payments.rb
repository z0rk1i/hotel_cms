class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :booking, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :method, null: false, default: "cash"
      t.datetime :paid_at, null: false
      t.text :note

      t.timestamps
    end

    add_index :payments, :paid_at
    add_index :payments, [ :booking_id, :paid_at ]
  end
end
