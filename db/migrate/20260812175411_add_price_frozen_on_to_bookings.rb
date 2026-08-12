class AddPriceFrozenOnToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :price_frozen_on, :date
  end
end
