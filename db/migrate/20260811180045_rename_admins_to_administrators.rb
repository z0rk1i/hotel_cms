class RenameAdminsToAdministrators < ActiveRecord::Migration[8.1]
  def change
    rename_table :admins, :administrators
  end
end
