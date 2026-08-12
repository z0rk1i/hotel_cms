module Admin
  class ClosedDatesController < CrudController
    private

    def index_records
      ClosedDate.ordered
    end

    def model_class
      ClosedDate
    end

    def resource_params
      params.require(:closed_date).permit(:date, :reason)
    end

    def resource_index_path
      admin_closed_dates_path
    end

    def created_notice
      "Дата закрытия добавлена."
    end

    def updated_notice
      "Дата закрытия обновлена."
    end

    def destroyed_notice
      "Дата закрытия удалена."
    end
  end
end
