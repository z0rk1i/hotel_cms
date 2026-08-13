class AccountController < ApplicationController
  def show
    @phone = params[:phone].to_s.strip
    @guest = User.guests.find_by(phone: @phone) if @phone.present?
    @stays = @guest&.stays&.order(check_in: :desc) || []
  end

  def find
    redirect_to account_path(phone: params[:phone].to_s.strip)
  end
end
