class CreateClosedDates < ActiveRecord::Migration[8.1]
  def change
    create_table :closed_dates do |t|
      t.date :date, null: false
      t.string :reason

      t.timestamps
    end

    add_index :closed_dates, :date, unique: true
  end
end
