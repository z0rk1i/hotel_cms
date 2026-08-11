class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  scope :unread, -> { where(read_at: nil) }
  scope :ordered, -> { order(created_at: :desc) }

  after_commit :deliver_email, on: :create

  def read?
    read_at.present?
  end

  def unread?
    read_at.blank?
  end

  private

  def deliver_email
    NotificationMailer.status_changed(self).deliver_later if user.email_deliverable?
  end
end
