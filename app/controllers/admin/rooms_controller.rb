module Admin
  class RoomsController < BaseController
    before_action :set_room, only: %i[edit update destroy]

    def index
      @rooms = Room.includes(:category).order(:floor, :number)
      @rooms = @rooms.where(status: params[:status]) if params[:status].present?
    end

    def available
      start_date = Date.parse(params[:check_in])
      end_date = Date.parse(params[:check_out])
      occupied = Booking.active_overlapping(start_date, end_date).select(:room_id)
      occupied = occupied.where.not(room_id: params[:exclude]) if params[:exclude].present?

      rooms = Room.where.not(id: occupied).order(:number)
      render json: rooms.map { |r| { id: r.id, label: r.label, price: r.price_per_night.to_f } }
    rescue ArgumentError, TypeError
      render json: []
    end

    def new
      @room = Room.new
    end

    def create
      @room = Room.new(room_params)

      if @room.save
        redirect_to admin_rooms_path, notice: "Номер создан."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @room.update(room_params)
        redirect_to admin_rooms_path, notice: "Номер обновлён."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @room.destroy
        redirect_to admin_rooms_path, notice: "Номер удалён."
      else
        redirect_to admin_rooms_path, alert: @room.errors.full_messages.to_sentence
      end
    end

    def destroy_photo
      @room = Room.find(params[:id])
      photo = @room.photos.find(params[:photo_id])
      photo.purge
      redirect_to edit_admin_room_path(@room), notice: "Фото удалено."
    end

    private

    def set_room
      @room = Room.find(params[:id])
    end

    def room_params
      params.require(:room).permit(:number, :category_id, :floor, :size_sqm, :capacity,
                                   :price_per_night, :status, :description, photos: [])
    end
  end
end
