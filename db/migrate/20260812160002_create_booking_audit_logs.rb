class CreateBookingAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :booking_audit_logs do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :administrator, null: true, foreign_key: true
      t.string :from_status
      t.string :to_status, null: false
      t.timestamps
    end
  end
end
