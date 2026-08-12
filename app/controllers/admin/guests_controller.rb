module Admin
  class GuestsController < BaseController
    before_action :set_guest, only: %i[edit update destroy]

    def index
      @guests = Guest.order(:full_name)
      @guests = @guests.search(params[:query]) if params[:query].present?

      respond_to do |format|
        format.html { @guests = paginate(@guests) }
        format.csv do
          send_data GuestsCsvExporter.export(@guests), filename: "guests-#{Date.current}.csv", type: "text/csv"
        end
      end
    end

    def new
      @guest = Guest.new
    end

    def create
      @guest = Guest.new(guest_params)

      if @guest.save
        redirect_to_previous admin_guests_path, notice: "Гость добавлен."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @guest.update(guest_params)
        redirect_to_previous admin_guests_path, notice: "Данные гостя обновлены."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @guest.destroy
        redirect_back_or admin_guests_path, notice: "Гость удалён."
      else
        redirect_back_or admin_guests_path, alert: @guest.errors.full_messages.to_sentence
      end
    end

    private

    def set_guest
      @guest = Guest.find(params[:id])
    end

    def guest_params
      params.require(:guest).permit(:full_name, :email, :phone, :passport_number, :notes)
    end
  end
end
