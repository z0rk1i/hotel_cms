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

    private

    def model_class
      Guest
    end

    def resource_params
      params.require(:guest).permit(:full_name, :email, :phone, :passport_number, :notes)
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
