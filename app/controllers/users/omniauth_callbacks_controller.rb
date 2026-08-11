module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def vkontakte
      handle_omniauth("VK")
    end

    def yandex
      handle_omniauth("Яндекс")
    end

    private

    def handle_omniauth(provider_name)
      @user = User.from_omniauth(request.env["omniauth.auth"])

      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :success, kind: provider_name)
      else
        session["devise.user_attributes"] = @user.attributes
        redirect_to new_user_registration_path, alert: @user.errors.full_messages.to_sentence
      end
    end

    def after_sign_in_path_for(_resource)
      bookings_path
    end
  end
end
