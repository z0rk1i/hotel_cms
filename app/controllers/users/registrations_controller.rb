module Users
  class RegistrationsController < Devise::RegistrationsController
    layout "auth"

    before_action :configure_sign_up_params, only: [ :create ]

    private

    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: %i[full_name phone])
    end
  end
end
