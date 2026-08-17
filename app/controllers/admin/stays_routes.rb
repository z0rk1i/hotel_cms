module Admin
  module StaysRoutes
    STAY_PARAMS = %i[room_id user_id check_in check_out guests_count status total_price notes].freeze

    def self.registered(app)
      app.get "/stays" do
        @stays = Stay.order(check_in: :desc)
        if params["status"].in?(%w[pending confirmed checked_in checked_out cancelled])
          @stays = @stays.public_send(params["status"])
        end
        @stays = @stays.where("check_in >= ?", Date.parse(params["from"])) if params["from"].present?
        @stays = @stays.where("check_out <= ?", Date.parse(params["to"])) if params["to"].present?
        if params["query"].present?
          q = "%#{params['query']}%"
          @stays = @stays.joins(:user).where("users.full_name ILIKE ? OR users.phone ILIKE ?", q, q)
        end
        haml :"admin/stays/index", layout: :admin
      rescue Date::Error
        session["flash"] = { "alert" => "Неверный формат дат" }
        redirect admin_stays_path
      end

      app.get "/stays/new" do
        @stay = Stay.new(check_in: Date.current + 1, check_out: Date.current + 2, guests_count: 1, status: :pending)
        haml :"admin/stays/new", layout: :admin
      end

      app.post "/stays" do
        @stay = Stay.new(stay_params)
        if @stay.save
          session["flash"] = { "notice" => "Бронь создана" }
          redirect admin_stay_path(@stay)
        else
          status 422
          haml :"admin/stays/new", layout: :admin
        end
      end

      app.get "/stays/:id" do
        @stay = Stay.includes(:room, :user).find(params["id"])
        haml :"admin/stays/show", layout: :admin
      end

      app.get "/stays/:id/edit" do
        @stay = Stay.includes(:room, :user).find(params["id"])
        haml :"admin/stays/edit", layout: :admin
      end

      app.patch "/stays/:id" do
        @stay = Stay.includes(:room, :user).find(params["id"])
        if @stay.update(stay_params)
          session["flash"] = { "notice" => "Бронь обновлена" }
          redirect admin_stay_path(@stay)
        else
          status 422
          haml :"admin/stays/edit", layout: :admin
        end
      end

      app.delete "/stays/:id" do
        @stay = Stay.find(params["id"])
        @stay.destroy!
        session["flash"] = { "notice" => "Бронь удалена" }
        redirect admin_stays_path
      rescue ActiveRecord::RecordNotDestroyed
        session["flash"] = { "alert" => "Не удалось удалить бронь" }
        redirect admin_stays_path
      end

      app.patch "/stays/:id/confirm" do
        transition { @stay.transition_to!("confirmed") }
      end

      app.patch "/stays/:id/check_in" do
        transition { @stay.transition_to!("checked_in") }
      end

      app.patch "/stays/:id/check_out" do
        transition { @stay.transition_to!("checked_out") }
      end

      app.patch "/stays/:id/cancel" do
        transition { @stay.transition_to!("cancelled") }
      end

      app.post "/stays/:id/add_payment" do
        @stay = Stay.find(params["id"])
        @stay.add_payment!(method: params["method"], amount: params["amount"],
                           paid_at: parse_date(params["paid_at"], fallback: Time.current).to_time, note: params["note"])
        session["flash"] = { "notice" => "Оплата добавлена" }
        redirect admin_stay_path(@stay)
      rescue ArgumentError => e
        session["flash"] = { "alert" => e.message }
        redirect admin_stay_path(@stay)
      end

      app.delete "/stays/:id/remove_payment/:payment_id" do
        @stay = Stay.find(params["id"])
        @stay.remove_payment!(params["payment_id"])
        session["flash"] = { "notice" => "Оплата удалена" }
        redirect admin_stay_path(@stay)
      end

      app.post "/stays/:id/add_service" do
        @stay = Stay.find(params["id"])
        @stay.add_service!(name: params["name"], price: params["price"],
                           quantity: params["quantity"], date: parse_date(params["date"], fallback: Date.current),
                           note: params["note"])
        session["flash"] = { "notice" => "Услуга добавлена" }
        redirect admin_stay_path(@stay)
      rescue ArgumentError => e
        session["flash"] = { "alert" => e.message }
        redirect admin_stay_path(@stay)
      end

      app.delete "/stays/:id/cancel_service/:service_id" do
        @stay = Stay.find(params["id"])
        @stay.cancel_service!(params["service_id"])
        session["flash"] = { "notice" => "Услуга отменена" }
        redirect admin_stay_path(@stay)
      end

      app.helpers do
        private

        def stay_params
          slice_params(params["stay"], STAY_PARAMS)
        end

        def transition
          @stay = Stay.find(params["id"])
          yield
          session["flash"] = { "notice" => "Статус обновлён" }
          redirect admin_stay_path(@stay)
        rescue ArgumentError, ActiveRecord::RecordInvalid => e
          session["flash"] = { "alert" => e.message }
          redirect admin_stay_path(@stay)
        end
      end
    end
  end
end
