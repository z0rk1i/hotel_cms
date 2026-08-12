module Admin
  class ServicesController < CrudController
    private

    def index_records
      Service.order(:name)
    end

    def model_class
      Service
    end

    def resource_params
      params.require(:service).permit(:name, :description, :price)
    end

    def resource_index_path
      admin_services_path
    end

    def created_notice
      "Услуга добавлена."
    end

    def updated_notice
      "Услуга обновлена."
    end

    def destroyed_notice
      "Услуга удалена."
    end
  end
end
