class CreateServiceOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :service_orders do |t|
      t.references :service, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :service_date, null: false
      t.integer :quantity, default: 1, null: false
      t.text :notes
      t.string :status, default: "pending", null: false
      t.decimal :total_price, precision: 12, scale: 2, default: "0.0", null: false

      t.timestamps
    end

    add_index :service_orders, [ :user_id, :status ]
    add_index :service_orders, :service_date
  end
end
