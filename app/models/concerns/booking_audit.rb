module BookingAudit
  extend ActiveSupport::Concern

  included do
    after_save :audit_status_change, if: -> { saved_change_to_status? }
  end

  private

  def audit_status_change
    BookingAuditLog.create(
      booking: self,
      administrator: Thread.current[:current_administrator],
      from_status: status_before_last_save,
      to_status: status
    )
  end
end
