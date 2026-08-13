module Admin
  class RoomsController < BaseController
    before_action :set_room, only: %i[edit update destroy complete_cleaning destroy_photo]

    def index
      @rooms = Room.order(:floor, :number)
      @rooms = @rooms.by_status(params[:status].downcase) if params[:status].present?
      @rooms = @rooms.search(params[:query]) if params[:query].present?
    end

    def new
      @room = Room.new(status: :available)
    end

    def create
      @room = Room.new(room_params)
      if @room.save
        redirect_to admin_rooms_path, notice: "Номер добавлен"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @room.update(room_params)
        redirect_to admin_rooms_path, notice: "Номер обновлён"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @room.destroy
        redirect_to admin_rooms_path, notice: "Номер удалён"
      else
        redirect_to admin_rooms_path, alert: @room.errors.full_messages.to_sentence
      end
    end

    def complete_cleaning
      @room.update!(status: :available)
      redirect_to admin_rooms_path, notice: "Уборка завершена, номер доступен"
    end

    def destroy_photo
      photo = @room.photos.find(params[:photo_id])
      photo.purge
      redirect_to edit_admin_room_path(@room), notice: "Фотография удалена"
    rescue ActiveRecord::RecordNotFound
      redirect_to edit_admin_room_path(@room), alert: "Фотография не найдена"
    end

    private

    def set_room
      @room = Room.find(params[:id])
    end

    def room_params
      params.require(:room).permit(
        :number, :category, :floor, :capacity, :size_sqm, :description,
        :price_per_night, :weekend_multiplier, :min_nights, :status,
        :unavailable_from, :unavailable_until, amenities: [], photos: []
      )
    end
  end
end
