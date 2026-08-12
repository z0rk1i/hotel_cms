module Admin
  class RoomsController < CrudController
    def index
      @rooms = Room.includes(:category).order(:floor, :number)
      @rooms = @rooms.where(status: params[:status]) if params[:status].present?
    end

    def available
      result = RoomAvailability.new.call(
        check_in: params[:check_in],
        check_out: params[:check_out],
        exclude_room_id: params[:exclude]
      )

      if result.success?
        render json: result.value!
      else
        render json: { error: "Укажите корректные даты" }, status: :unprocessable_entity
      end
    end

    def destroy_photo
      room = Room.find(params[:room_id])
      photo = room.photos.find(params[:photo_id])
      photo.purge
      redirect_to edit_admin_room_path(room), notice: "Фото удалено."
    end

    private

    def model_class
      Room
    end

    def resource_params
      params.require(:room).permit(:number, :category_id, :floor, :size_sqm, :capacity,
                                   :price_per_night, :weekend_multiplier, :status, :description,
                                   :unavailable_from, :unavailable_until,
                                   photos: [], amenity_ids: [])
    end

    def resource_index_path
      admin_rooms_path
    end

    def created_notice
      "Номер создан."
    end

    def updated_notice
      "Номер обновлён."
    end

    def destroyed_notice
      "Номер удалён."
    end
  end
end
