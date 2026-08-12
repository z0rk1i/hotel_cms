class CreateRoomAmenities < ActiveRecord::Migration[8.1]
  def change
    create_table :room_amenities do |t|
      t.references :room, null: false, foreign_key: true
      t.references :amenity, null: false, foreign_key: true

      t.timestamps
    end

    add_index :room_amenities, [ :room_id, :amenity_id ], unique: true
  end
end
