class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :reviewable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :body, null: false
      t.string :status, default: "pending", null: false

      t.timestamps
    end

    add_index :reviews, [ :reviewable_type, :reviewable_id, :status ]
    add_index :reviews, [ :user_id, :reviewable_type, :reviewable_id ]
  end
end
