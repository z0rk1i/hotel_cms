module Admin
  module RoomsRoutes
    ROOM_PARAMS = %i[number category floor capacity size_sqm description
                     price_per_night weekend_multiplier min_nights status
                     unavailable_from unavailable_until].freeze

    def self.registered(app)
      app.get "/rooms" do
        @rooms = Room.order(:floor, :number)
        @rooms = @rooms.by_status(params["status"].downcase) if params["status"].present?
        @rooms = @rooms.search(params["query"]) if params["query"].present?
        haml :"admin/rooms/index", layout: :admin
      end

      app.get "/rooms/new" do
        @room = Room.new(status: :available)
        haml :"admin/rooms/new", layout: :admin
      end

      app.post "/rooms" do
        @room = Room.new(room_params)
        if @room.save
          attach_uploaded_photos(@room)
          session["flash"] = { "notice" => "Номер добавлен" }
          redirect admin_rooms_path
        else
          status 422
          haml :"admin/rooms/new", layout: :admin
        end
      end

      app.get "/rooms/:id/edit" do
        @room = Room.find(params["id"])
        haml :"admin/rooms/edit", layout: :admin
      end

      app.patch "/rooms/:id" do
        @room = Room.find(params["id"])
        if @room.update(room_params)
          attach_uploaded_photos(@room)
          session["flash"] = { "notice" => "Номер обновлён" }
          redirect admin_rooms_path
        else
          status 422
          haml :"admin/rooms/edit", layout: :admin
        end
      end

      app.delete "/rooms/:id" do
        @room = Room.find(params["id"])
        if @room.destroy
          session["flash"] = { "notice" => "Номер удалён" }
        else
          session["flash"] = { "alert" => @room.errors.full_messages.to_sentence }
        end
        redirect admin_rooms_path
      end

      app.patch "/rooms/:id/complete_cleaning" do
        @room = Room.find(params["id"])
        @room.update!(status: :available)
        session["flash"] = { "notice" => "Уборка завершена, номер доступен" }
        redirect admin_rooms_path
      end

      app.delete "/rooms/:id/photo/:photo_id" do
        @room = Room.find(params["id"])
        photo = @room.photos.find(params["photo_id"])
        photo.destroy_with_files!
        session["flash"] = { "notice" => "Фотография удалена" }
        redirect edit_admin_room_path(@room)
      rescue ActiveRecord::RecordNotFound
        session["flash"] = { "alert" => "Фотография не найдена" }
        redirect edit_admin_room_path(@room)
      end

      app.helpers do
        private

        def room_params
          slice_params(params["room"], ROOM_PARAMS).merge(
            amenities: Array(params["room"]&.[]("amenities")).reject { |v| v == "" }
          )
        end

        def attach_uploaded_photos(room)
          files = params["photos"]
          return if files.blank?

          files = [ files ] unless files.is_a?(Array)
          files.each_with_index do |file, idx|
            next unless file.respond_to?(:tempfile) && file[:tempfile] && file[:tempfile].size.positive?

            RoomPhoto.attach_file(room, file[:tempfile].path, file[:filename], position: room.photos.count + idx + 1)
          end
        end
      end
    end
  end
end
