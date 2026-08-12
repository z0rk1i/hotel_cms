class CreateConsentLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :consent_logs do |t|
      t.references :guest, null: false, foreign_key: true
      t.datetime :signed_at, null: false

      t.timestamps
    end

    add_index :consent_logs, :signed_at
  end
end
