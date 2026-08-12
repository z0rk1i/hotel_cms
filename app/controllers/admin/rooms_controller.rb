module Admin
  class RoomsController < BaseController
    before_action :set_room, only: %i[edit update destroy]

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
      render json: result.value_or([])
    end

    def new
      @room = Room.new
    end

    def create
      @room = Room.new(room_params)

      if @room.save
        redirect_to_previous admin_rooms_path, notice: "Номер создан."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @room.update(room_params)
        redirect_to_previous admin_rooms_path, notice: "Номер обновлён."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @room.destroy
        redirect_back_or admin_rooms_path, notice: "Номер удалён."
      else
        redirect_back_or admin_rooms_path, alert: @room.errors.full_messages.to_sentence
      end
    end

    def destroy_photo
      room = Room.find(params[:room_id])
      photo = room.photos.find(params[:photo_id])
      photo.purge
      redirect_to edit_admin_room_path(room), notice: "Фото удалено."
    end

    private

    def set_room
      @room = Room.find(params[:id])
    end

    def room_params
      params.require(:room).permit(:number, :category_id, :floor, :size_sqm, :capacity,
                                   :price_per_night, :status, :description, :unavailable_from, :unavailable_until,
                                   photos: [], amenity_ids: [])
    end
  end
end
