module Admin
  class GuestsController < CrudController
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

    def show
      @guest = Guest.find(params[:id])
      @bookings = @guest.bookings.includes(:room, :payments).order(check_in: :desc)
      @duplicates = @guest.possible_duplicates
    end

    def merge
      @guest = Guest.find(params[:id])
      duplicate = Guest.find(params[:duplicate_id])

      if duplicate.nil? || duplicate.id == @guest.id
        redirect_to admin_guest_path(@guest), alert: "Нельзя объединить гостя с самим собой."
        return
      end

      duplicate.merge_into!(@guest)
      if duplicate.destroyed?
        redirect_to admin_guest_path(@guest), notice: "Гость «#{duplicate.full_name}» объединён — его брони перенесены."
      else
        redirect_to admin_guest_path(@guest), alert: duplicate.errors.full_messages.to_sentence
      end
    end

    private

    def model_class
      Guest
    end

    def resource_params
      params.require(:guest).permit(:full_name, :email, :phone, :passport_number, :notes, :is_vip, :preferences)
    end

    def resource_index_path
      admin_guests_path
    end

    def created_notice
      "Гость добавлен."
    end

    def updated_notice
      "Данные гостя обновлены."
    end

    def destroyed_notice
      "Гость удалён."
    end
  end
end
