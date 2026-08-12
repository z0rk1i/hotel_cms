class AddUniqueIndexToReviews < ActiveRecord::Migration[8.1]
  def up
    remove_index :reviews, name: "index_reviews_on_user_id_and_reviewable_type_and_reviewable_id"
    add_index :reviews, %i[user_id reviewable_type reviewable_id],
              unique: true,
              name: "index_reviews_on_user_reviewable_unique"
  end

  def down
    remove_index :reviews, name: "index_reviews_on_user_reviewable_unique"
    add_index :reviews, %i[user_id reviewable_type reviewable_id],
              name: "index_reviews_on_user_id_and_reviewable_type_and_reviewable_id"
  end
end
