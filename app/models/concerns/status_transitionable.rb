module StatusTransitionable
  extend ActiveSupport::Concern

  included do
    validate :status_transition_legal, on: :update, if: -> { status_changed? }
  end

  class_methods do
    def transitions_for(map)
      @status_transitions = map.transform_keys(&:to_sym)
                               .transform_values { |statuses| Array(statuses).map(&:to_sym) }
                               .freeze
    end

    def status_transitions
      @status_transitions
    end
  end

  def can_transition_to?(new_status)
    self.class.status_transitions.fetch(status.to_sym, []).include?(new_status.to_sym)
  end

  def transition_to(new_status)
    return false unless can_transition_to?(new_status)

    update!(status: new_status)
    true
  rescue ActiveRecord::RecordInvalid
    self.status = status_was
    false
  end

  private

  def status_transition_legal
    from = status_was.to_sym
    to = status.to_sym
    return if self.class.status_transitions.fetch(from, []).include?(to)

    errors.add(:status, "нельзя изменить с «#{self.class.status_labels.fetch(status_was.to_s, status_was)}» на «#{self.class.status_labels.fetch(status.to_s, status)}»")
  end
end
