module Admin
  module UsersRoutes
    def self.registered(app)
      app.get "/users" do
        @users = User.order(:role, :full_name)
        @users = @users.guests if params["type"] == "guests"
        @users = @users.where(is_vip: true) if params["vip"].present?
        @users = @users.search(params["query"]) if params["query"].present?
        haml :"admin/users/index", layout: :admin
      end

      app.get "/users/:id" do
        @user = User.find(params["id"])
        @stays = @user.stays.order(check_in: :desc)
        haml :"admin/users/show", layout: :admin
      end

      app.delete "/users/:id" do
        @user = User.find(params["id"])
        if @user.destroy
          session["flash"] = { "notice" => "Пользователь удалён" }
        else
          session["flash"] = { "alert" => @user.errors.full_messages.to_sentence }
        end
        redirect admin_users_path
      end

      app.patch "/users/:id/toggle_vip" do
        @user = User.find(params["id"])
        @user.update!(is_vip: !@user.is_vip)
        session["flash"] = { "notice" => @user.is_vip ? "VIP" : "Не VIP" }
        redirect admin_user_path(@user)
      end

      app.post "/users/:id/merge_into" do
        @user = User.find(params["id"])
        target = User.find(params["target_user_id"])
        @user.merge_into!(target)
        session["flash"] = { "notice" => "Профили объединены" }
        redirect admin_user_path(target)
      rescue ActiveRecord::RecordNotFound
        session["flash"] = { "alert" => "Пользователь не найден" }
        redirect admin_user_path(@user)
      end
    end
  end
end
