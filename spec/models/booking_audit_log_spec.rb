require 'rails_helper'

RSpec.describe BookingAuditLog, type: :model do
  it "belongs to a booking" do
    log = create(:booking_audit_log)
    expect(log.booking).to be_present
  end

  it "allows a nil administrator" do
    expect(build(:booking_audit_log)).to be_valid
  end

  describe "audit trail on booking transitions" do
    it "records a status change with the from and to statuses" do
      booking = create(:booking, :pending)
      booking.transition_to(:confirmed)

      log = booking.audit_logs.last
      expect(log.from_status).to eq("pending")
      expect(log.to_status).to eq("confirmed")
    end

    it "captures the current administrator" do
      admin = create(:administrator)
      Thread.current[:current_administrator] = admin
      booking = create(:booking, :pending)
      booking.transition_to(:confirmed)

      expect(booking.audit_logs.last.administrator).to eq(admin)
    ensure
      Thread.current[:current_administrator] = nil
    end

    it "records a nil administrator for system transitions" do
      booking = create(:booking, :pending)
      booking.transition_to(:cancelled)

      expect(booking.audit_logs.last.administrator).to be_nil
    end

    it "does not record an entry when status does not change" do
      booking = create(:booking, :confirmed)
      expect { booking.update(notes: "Обновлено") }.not_to change(BookingAuditLog, :count)
    end

    it "orders entries newest first" do
      booking = create(:booking)
      booking.transition_to(:confirmed)
      booking.transition_to(:cancelled)

      expect(booking.audit_logs.ordered.first.to_status).to eq("cancelled")
    end
  end
end
