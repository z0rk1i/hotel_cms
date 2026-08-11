class CreateRoomCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :room_categories do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :base_price, precision: 10, scale: 2, null: false, default: 0

      t.timestamps
    end
  end
end
