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
    build_user

    @booking = Booking.new(booking_params.merge(user: @user, guest: find_or_create_guest, status: :pending))

    if @user.persisted? && @booking.save
      sign_in(@user, scope: :user) unless user_signed_in?
      redirect_to account_path, notice: "Бронь создана! Ожидает подтверждения отеля."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @booking = current_user.bookings.includes(:room, :guest).find(params[:id])
  end

  def available_rooms
    start_date = Date.parse(params[:check_in])
    end_date = Date.parse(params[:check_out])
    occupied = Booking.active_overlapping(start_date, end_date).select(:room_id)
    rooms = Room.where.not(id: occupied).order(:number)
    render json: rooms.map { |r| { id: r.id, label: r.label, price: r.price_per_night.to_f } }
  rescue ArgumentError, TypeError
    render json: []
  end

  private

  def build_user
    @user = current_user
    return if @user

    @user = User.new(user_params)
    @user.save
  end

  def find_or_create_guest
    guest = Guest.find_or_initialize_by(email: @user.email)
    guest.full_name = @user.full_name if guest.full_name.blank?
    guest.phone = @user.phone if guest.phone.present? && guest.phone.blank?
    guest.save
    guest
  end

  def user_params
    params.require(:user).permit(:full_name, :email, :phone, :password, :password_confirmation)
  end

  def booking_params
    params.require(:booking).permit(:room_id, :check_in, :check_out, :guests_count, :notes)
  end
end
