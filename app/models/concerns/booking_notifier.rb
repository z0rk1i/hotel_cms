module BookingNotifier
  extend ActiveSupport::Concern

  included do
    after_commit :deliver_created_email, on: :create
    after_update :deliver_status_email, if: -> { saved_change_to_status? }
    after_commit :notify_admins_of_new_booking, on: :create
  end

  private

  def deliver_created_email
    return unless email_deliverable?

    BookingMailer.created(self).deliver_later
  end

  def deliver_status_email
    return unless email_deliverable?

    case status
    when "confirmed" then BookingMailer.confirmed(self).deliver_later
    when "cancelled" then BookingMailer.cancelled(self).deliver_later
    end
  end

  def email_deliverable?
    user&.email_deliverable?
  end

  def notify_admins_of_new_booking
    AdminMailer.new_booking(self).deliver_later if Administrator.exists?
  end
end
