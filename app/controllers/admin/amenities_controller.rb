module Admin
  class AmenitiesController < BaseController
    before_action :set_amenity, only: %i[edit update destroy]

    def index
      @amenities = Amenity.order(:name)
    end

    def new
      @amenity = Amenity.new
    end

    def create
      @amenity = Amenity.new(amenity_params)

      if @amenity.save
        redirect_to_previous admin_amenities_path, notice: "Удобство добавлено."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @amenity.update(amenity_params)
        redirect_to_previous admin_amenities_path, notice: "Удобство обновлено."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @amenity.destroy
      redirect_back_or admin_amenities_path, notice: "Удобство удалено."
    end

    private

    def set_amenity
      @amenity = Amenity.find(params[:id])
    end

    def amenity_params
      params.require(:amenity).permit(:name, :icon)
    end
  end
end
