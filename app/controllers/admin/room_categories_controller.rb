module Admin
  class RoomCategoriesController < CrudController
    private

    def index_records
      RoomCategory.order(:name)
    end

    def model_class
      RoomCategory
    end

    def resource_params
      params.require(:room_category).permit(:name, :description, :base_price)
    end

    def resource_index_path
      admin_room_categories_path
    end

    def created_notice
      "Категория создана."
    end

    def updated_notice
      "Категория обновлена."
    end

    def destroyed_notice
      "Категория удалена."
    end
  end
end
