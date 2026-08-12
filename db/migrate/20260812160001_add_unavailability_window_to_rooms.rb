class AddUnavailabilityWindowToRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :rooms, :unavailable_from, :date
    add_column :rooms, :unavailable_until, :date
  end
end
