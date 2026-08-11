module Users
  class SessionsController < Devise::SessionsController
    layout "auth"

    private

    def after_sign_in_path_for(_resource)
      account_path
    end
  end
end
