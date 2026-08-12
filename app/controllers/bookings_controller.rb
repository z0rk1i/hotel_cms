class BookingsController < ApplicationController
  layout "public"

  before_action :authenticate_user!, only: %i[show]

  def new
    @booking = Booking.new
    @booking.check_in = Date.current + 1
    @booking.check_out = Date.current + 2
    @booking.guests_count = 1
    @booking.room_id = params[:room_id] if params[:room_id].present?
    @user = current_user || User.new
  end

  def create
    result = BookingCreator.new.call(
      current_user: current_user,
      booking_attrs: booking_params,
      user_attrs: (user_signed_in? ? {} : user_params)
    )

    if result.success?
      @booking = result.value!.booking
      @user = result.value!.user
      sign_in(@user, scope: :user) unless user_signed_in?
      redirect_to account_path, notice: "Бронь создана! Ожидает подтверждения отеля."
    else
      @booking = result.failure.booking
      @user = result.failure.user
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @booking = current_user.bookings.includes(:room, :guest).find(params[:id])
  end

  def available_rooms
    result = RoomAvailability.new.call(check_in: params[:check_in], check_out: params[:check_out])
    render json: result.value_or([])
  end

  private

  def user_params
    params.require(:user).permit(:full_name, :email, :phone, :password, :password_confirmation)
  end

  def booking_params
    params.require(:booking).permit(:room_id, :check_in, :check_out, :guests_count, :notes)
  end
end
