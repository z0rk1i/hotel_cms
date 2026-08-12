class CreatePricePeriods < ActiveRecord::Migration[8.1]
  def change
    create_table :price_periods do |t|
      t.string :name, null: false
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.decimal :multiplier, precision: 5, scale: 2, null: false, default: 1.0
      t.timestamps
    end
    add_index :price_periods, [ :starts_on, :ends_on ]
  end
end
