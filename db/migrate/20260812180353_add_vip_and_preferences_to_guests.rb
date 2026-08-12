class AddVipAndPreferencesToGuests < ActiveRecord::Migration[8.1]
  def change
    add_column :guests, :is_vip, :boolean, null: false, default: false
    add_column :guests, :preferences, :string
  end
end
