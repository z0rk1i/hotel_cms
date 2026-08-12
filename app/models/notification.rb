class Notification < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :notifiable, polymorphic: true

  scope :unread, -> { where(read_at: nil) }
  scope :ordered, -> { order(created_at: :desc) }
  scope :for_admin, -> { where(to_admin: true) }

  after_commit :deliver_email, on: :create

  def read?
    read_at.present?
  end

  def unread?
    read_at.blank?
  end

  def recipient_title
    to_admin? ? "Администрация" : user.full_name
  end

  private

  def deliver_email
    return if to_admin?
    return if kind == "booking_status"
    return unless user&.email_deliverable?

    NotificationMailer.status_changed(self).deliver_later
  end
end
