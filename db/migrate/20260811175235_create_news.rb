class CreateNews < ActiveRecord::Migration[8.1]
  def change
    create_table :news do |t|
      t.string :title, null: false
      t.text :body
      t.datetime :published_at

      t.timestamps
    end

    add_index :news, :published_at
  end
end
