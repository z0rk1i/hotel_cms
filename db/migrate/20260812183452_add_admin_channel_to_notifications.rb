class AddAdminChannelToNotifications < ActiveRecord::Migration[8.1]
  def change
    change_column_null :notifications, :user_id, true
    add_column :notifications, :to_admin, :boolean, null: false, default: false
    add_index :notifications, [ :to_admin, :read_at ]
  end
end
