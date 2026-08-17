module Admin
  module AuthRoutes
    def self.registered(app)
      app.get "/users/sign_in" do
        redirect admin_root_path if current_user&.admin?
        haml :"users/sessions/new", layout: :auth
      end

      app.post "/users/sign_in" do
        user = User.find_by(email: params["email"].to_s.strip.downcase)
        if user&.valid_password?(params["password"].to_s)
          session["user_id"] = user.id
          redirect user.admin? ? admin_root_path : root_path
        else
          session["flash"] = { "alert" => "Неверный email или пароль" }
          redirect new_user_session_path
        end
      end

      app.post "/users/sign_out" do
        session.clear
        redirect new_user_session_path
      end

      app.delete "/users/sign_out" do
        session.clear
        redirect new_user_session_path
      end
    end
  end
end
