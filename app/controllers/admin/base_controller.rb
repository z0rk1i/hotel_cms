module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :authenticate_administrator!
    before_action :store_return_to
    before_action :track_current_administrator
    after_action :clear_current_administrator

    include Pagy::Backend

    private

    def track_current_administrator
      Thread.current[:current_administrator] = current_administrator
    end

    def clear_current_administrator
      Thread.current[:current_administrator] = nil
    end

    def redirect_back_or(default, **options)
      redirect_to safe_referer || default, **options
    end

    def redirect_to_previous(default, **options)
      redirect_to session.delete(:return_to) || default, **options
    end

    def store_return_to
      return unless %w[new edit].include?(action_name)
      return unless request.get?

      session[:return_to] = safe_referer if safe_referer.present?
    end

    def safe_referer
      referer = request.referer
      return nil if referer.blank?

      uri = URI.parse(referer)
      return nil unless uri.host == request.host

      uri.path
    rescue URI::InvalidURIError
      nil
    end

    def paginate(scope, default_per = 25)
      @pagy, items = pagy(scope, items: default_per)
      items
    end

    def transition_alert(record, action)
      record.errors.full_messages.presence&.to_sentence || "Невозможно #{action} в текущем статусе."
    end
  end
end
