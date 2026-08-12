class CreateRoomStatusLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :room_status_logs do |t|
      t.references :room, null: false, foreign_key: true
      t.string :from_status, null: false
      t.string :to_status, null: false

      t.timestamps
    end
  end
end
