class CreateRatelimitCounters < ActiveRecord::Migration[8.1]
  def change
    create_table :ratelimit_counters do |t|
      t.string :name, null: false
      t.string :classification, null: false
      t.bigint :epoch, null: false
      t.integer :count, null: false, default: 0

      t.timestamps
    end

    add_index :ratelimit_counters, %i[name classification epoch], unique: true, name: "index_ratelimit_counters_unique"
  end
end
