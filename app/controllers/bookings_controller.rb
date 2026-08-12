class BookingsController < ApplicationController
  layout "public"

  before_action :authenticate_user!, only: %i[show cancel]

  def new
    @booking = Booking.new
    @booking.check_in = parse_date_param(params[:check_in]) || Date.current + 1
    @booking.check_out = parse_date_param(params[:check_out]) || Date.current + 2
    @booking.guests_count = 1
    @booking.room_id = params[:room_id] if params[:room_id].present?
    @user = current_user || User.new
  end

  def create
    result = BookingCreator.new.call(
      current_user: current_user,
      booking_attrs: booking_params,
      user_attrs: (user_signed_in? ? {} : user_params),
      consent_given: params[:consent_given] == "1"
    )

    payload = result.value_or(result.failure)
    @booking = payload.booking
    @user = payload.user

    if result.success?
      sign_in(@user, scope: :user) unless user_signed_in?
      redirect_to account_path, notice: "Бронь создана! Ожидает подтверждения отеля."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @booking = current_user.bookings.includes(:room, :guest).find(params[:id])
  end

  def cancel
    @booking = current_user.bookings.find(params[:id])
    if %w[pending confirmed].include?(@booking.status) && @booking.transition_to(:cancelled)
      redirect_to account_path, notice: "Бронь отменена."
    else
      redirect_to account_path, alert: "Эту бронь нельзя отменить в текущем статусе."
    end
  end

  def available_rooms
    result = RoomAvailability.new.call(check_in: params[:check_in], check_out: params[:check_out])

    if result.success?
      render json: result.value!
    else
      render json: { error: availability_error_message(result.failure) }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:full_name, :email, :phone, :password, :password_confirmation)
  end

  def parse_date_param(value)
    DateParams.parse(value)
  end

  def availability_error_message(failure)
    return failure if failure.is_a?(String)

    "Укажите корректные даты"
  end

  def booking_params
    params.require(:booking).permit(:room_id, :check_in, :check_out, :guests_count, :notes)
  end
end
