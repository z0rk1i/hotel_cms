class AddGuestsCountToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :guests_count, :integer, null: false, default: 1
  end
end
