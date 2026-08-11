module Admin
  class BookingsController < BaseController
    before_action :set_booking, only: %i[edit update destroy confirm check_in check_out cancel]

    def index
      @bookings = Booking.includes(:guest, :room)
      @bookings = @bookings.where(status: params[:status]) if params[:status].present?
      @bookings = @bookings.order(check_in: :desc)
      @bookings = paginate(@bookings)
    end

    def new
      @booking = Booking.new
      @booking.check_in = Date.current
      @booking.check_out = Date.current + 1
      @booking.guest_id = params[:guest_id] if params[:guest_id].present?
      @booking.room_id = params[:room_id] if params[:room_id].present?
      @booking.guests_count = 1
    end

    def create
      @booking = Booking.new(booking_params)

      if @booking.save
        redirect_to admin_bookings_path, notice: "Бронь создана."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @booking.update(booking_params)
        redirect_to admin_bookings_path, notice: "Бронь обновлена."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @booking.destroy
      redirect_to admin_bookings_path, notice: "Бронь удалена."
    end

    def confirm
      @booking.confirmed!
      redirect_to admin_bookings_path, notice: "Бронь подтверждена."
    end

    def check_in
      if @booking.checked_in!
        @booking.room.occupied!
        redirect_to admin_bookings_path, notice: "Гость заселён."
      end
    end

    def check_out
      @booking.checked_out!
      @booking.room.available!
      redirect_to admin_bookings_path, notice: "Гость выселен."
    end

    def cancel
      @booking.cancelled!
      redirect_to admin_bookings_path, notice: "Бронь отменена."
    end

    private

    def set_booking
      @booking = Booking.find(params[:id])
    end

    def booking_params
      params.require(:booking).permit(:guest_id, :room_id, :check_in, :check_out,
                                      :guests_count, :status, :notes)
    end
  end
end
