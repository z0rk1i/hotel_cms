class CreateAmenities < ActiveRecord::Migration[8.1]
  def change
    create_table :amenities do |t|
      t.string :name, null: false
      t.string :icon, null: false, default: "star"

      t.timestamps
    end
  end
end
