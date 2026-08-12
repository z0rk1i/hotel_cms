module Admin
  class BookingsController < BaseController
    before_action :set_booking, only: %i[show edit update destroy confirm check_in check_out cancel]

    def index
      @bookings = Booking.includes(:guest, :room)
      @bookings = @bookings.where(status: params[:status]) if params[:status].present?
      @bookings = @bookings.order(check_in: :desc)

      respond_to do |format|
        format.html { @bookings = paginate(@bookings) }
        format.csv do
          send_data BookingsCsvExporter.export(@bookings), filename: "bookings-#{Date.current}.csv", type: "text/csv"
        end
      end
    end

    def calendar
      @month = parse_month(params[:month])
      @prev_month = @month.prev_month
      @next_month = @month.next_month
      range_start = @month.beginning_of_month
      range_end = @month.end_of_month

      @rooms = Room.order(:floor, :number).includes(:category)
      bookings = Booking.includes(:guest)
                        .where.not(status: :cancelled)
                        .for_period(range_start, range_end.next_day)
      @bookings_by_room = bookings.group_by(&:room_id)

      @calendar = @rooms.map do |room|
        {
          room: room,
          bookings: visible_bookings(@bookings_by_room[room.id].to_a, range_start, range_end)
        }
      end
    end

    def show; end

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
        redirect_to_previous admin_booking_path(@booking), notice: "Бронь создана."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @booking.update(booking_params)
        redirect_to_previous admin_booking_path(@booking), notice: "Бронь обновлена."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @booking.destroy
      redirect_back fallback_location: admin_bookings_path, notice: "Бронь удалена."
    end

    def confirm
      if @booking.transition_to(:confirmed)
        redirect_back fallback_location: admin_booking_path(@booking), notice: "Бронь подтверждена."
      else
        redirect_back fallback_location: admin_booking_path(@booking), alert: transition_alert(@booking, "подтвердить")
      end
    end

    def check_in
      if @booking.transition_to(:checked_in)
        redirect_back fallback_location: admin_booking_path(@booking), notice: "Гость заселён."
      else
        redirect_back fallback_location: admin_booking_path(@booking), alert: transition_alert(@booking, "заселить гостя")
      end
    end

    def check_out
      if @booking.transition_to(:checked_out)
        redirect_back fallback_location: admin_booking_path(@booking), notice: "Гость выселен."
      else
        redirect_back fallback_location: admin_booking_path(@booking), alert: transition_alert(@booking, "выселить гостя")
      end
    end

    def cancel
      if @booking.transition_to(:cancelled)
        redirect_back fallback_location: admin_booking_path(@booking), notice: "Бронь отменена."
      else
        redirect_back fallback_location: admin_booking_path(@booking), alert: transition_alert(@booking, "отменить бронь")
      end
    end

    private

    def set_booking
      @booking = Booking.find(params[:id])
    end

    def parse_month(value)
      return Date.current.beginning_of_month if value.blank?

      Date.strptime(value, "%Y-%m")
    rescue ArgumentError
      Date.current.beginning_of_month
    end

    def visible_bookings(bookings, range_start, range_end)
      bookings.sort_by(&:check_in).map do |booking|
        start = [ booking.check_in, range_start ].max
        finish = [ booking.check_out, range_end.next_day ].min
        next if start >= finish

        {
          booking: booking,
          col_start: (start - range_start).to_i,
          col_span: (finish - start).to_i
        }
      end.compact
    end

    def booking_params
      params.require(:booking).permit(:guest_id, :room_id, :check_in, :check_out,
                                      :guests_count, :status, :notes)
    end
  end
end
