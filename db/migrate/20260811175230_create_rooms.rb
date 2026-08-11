class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.string :number, null: false
      t.references :category, null: false, foreign_key: { to_table: :room_categories }
      t.integer :floor, null: false, default: 1
      t.integer :size_sqm
      t.integer :capacity, null: false, default: 1
      t.decimal :price_per_night, precision: 10, scale: 2, null: false, default: 0
      t.string :status, null: false, default: "available"
      t.text :description

      t.timestamps
    end

    add_index :rooms, :number, unique: true
    add_index :rooms, :status
  end
end
