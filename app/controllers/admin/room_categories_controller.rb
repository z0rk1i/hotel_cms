module Admin
  class RoomCategoriesController < BaseController
    before_action :set_room_category, only: %i[edit update destroy]

    def index
      @room_categories = RoomCategory.order(:name)
    end

    def new
      @room_category = RoomCategory.new
    end

    def create
      @room_category = RoomCategory.new(room_category_params)

      if @room_category.save
        redirect_to admin_room_categories_path, notice: "Категория создана."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @room_category.update(room_category_params)
        redirect_to admin_room_categories_path, notice: "Категория обновлена."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @room_category.destroy
        redirect_to admin_room_categories_path, notice: "Категория удалена."
      else
        redirect_to admin_room_categories_path, alert: @room_category.errors.full_messages.to_sentence
      end
    end

    private

    def set_room_category
      @room_category = RoomCategory.find(params[:id])
    end

    def room_category_params
      params.require(:room_category).permit(:name, :description, :base_price)
    end
  end
end
