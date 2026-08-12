module StatusNotifiable
  extend ActiveSupport::Concern

  included do
    after_update :notify_status_change, if: -> { saved_change_to_status? }
  end

  private

  def notify_status_change
    return unless respond_to?(:user) && user

    user.notifications.create!(
      notifiable: self,
      kind: notification_kind,
      title: notification_title,
      body: notification_body
    )
  end

  def notification_kind
    raise NotImplementedError, "#{self.class} must implement ##{__method__}"
  end

  def notification_title
    raise NotImplementedError, "#{self.class} must implement ##{__method__}"
  end

  def notification_body
    raise NotImplementedError, "#{self.class} must implement ##{__method__}"
  end
end
