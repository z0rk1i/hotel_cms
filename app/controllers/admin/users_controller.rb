module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[show destroy toggle_vip merge_into]

    def index
      @users = User.order(:role, :full_name)
      @users = @users.guests if params[:type] == "guests"
      @users = @users.where(is_vip: true) if params[:vip].present?
      @users = @users.search(params[:query]) if params[:query].present?
    end

    def show
      @stays = @user.stays.order(check_in: :desc)
    end

    def destroy
      if @user.destroy
        redirect_to admin_users_path, notice: "Пользователь удалён"
      else
        redirect_to admin_users_path, alert: @user.errors.full_messages.to_sentence
      end
    end

    def toggle_vip
      @user.update!(is_vip: !@user.is_vip)
      redirect_to admin_user_path(@user), notice: @user.is_vip ? "VIP" : "Не VIP"
    end

    def merge_into
      target = User.find(params[:target_user_id])
      @user.merge_into!(target)
      redirect_to admin_user_path(target), notice: "Профили объединены"
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_user_path(@user), alert: "Пользователь не найден"
    end

    private

    def set_user
      @user = User.find(params[:id])
    end
  end
end
