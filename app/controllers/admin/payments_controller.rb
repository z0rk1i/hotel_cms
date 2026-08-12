module Admin
  class PaymentsController < BaseController
    before_action :set_booking
    before_action :set_payment, only: %i[destroy]

    def new
      @payment = @booking.payments.new
      @payment.paid_at = Time.current
      @payment.amount = [ @booking.due_amount, 0 ].max
    end

    def create
      @payment = @booking.payments.new(payment_params)

      if @payment.save
        redirect_to admin_booking_path(@booking), notice: "Оплата добавлена."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @payment.destroy
      redirect_to admin_booking_path(@booking), notice: "Оплата удалена."
    end

    private

    def set_booking
      @booking = Booking.find(params[:booking_id])
    end

    def set_payment
      @payment = @booking.payments.find(params[:id])
    end

    def payment_params
      params.require(:payment).permit(:amount, :method, :paid_at, :note)
    end
  end
end
