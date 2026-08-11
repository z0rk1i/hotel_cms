class CreateGuests < ActiveRecord::Migration[8.1]
  def change
    create_table :guests do |t|
      t.string :full_name, null: false
      t.string :email
      t.string :phone
      t.string :passport_number
      t.text :notes

      t.timestamps
    end

    add_index :guests, :email
    add_index :guests, :phone
  end
end
