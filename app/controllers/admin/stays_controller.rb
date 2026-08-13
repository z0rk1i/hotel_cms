module Admin
  class StaysController < BaseController
    before_action :set_stay, only: %i[show edit update destroy confirm check_in check_out cancel
                                      add_payment remove_payment add_service cancel_service]

    def index
      @stays = Stay.order(check_in: :desc)
      @stays = @stays.public_send(params[:status]) if params[:status].in?(%w[pending confirmed checked_in checked_out cancelled])
      @stays = @stays.where("check_in >= ?", Date.parse(params[:from])) if params[:from].present?
      @stays = @stays.where("check_out <= ?", Date.parse(params[:to])) if params[:to].present?
      @stays = @stays.joins(:user).where("users.full_name ILIKE ? OR users.phone ILIKE ?", "%#{params[:query]}%", "%#{params[:query]}%") if params[:query].present?
    rescue Date::Error
      redirect_to admin_stays_path, alert: "Неверный формат дат"
    end

    def show
    end

    def new
      @stay = Stay.new(check_in: Date.current + 1, check_out: Date.current + 2, guests_count: 1, status: :pending)
    end

    def create
      @stay = Stay.new(stay_params)
      if @stay.save
        redirect_to admin_stay_path(@stay), notice: "Бронь создана"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @stay.update(stay_params)
        redirect_to admin_stay_path(@stay), notice: "Бронь обновлена"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @stay.destroy!
      redirect_to admin_stays_path, notice: "Бронь удалена"
    rescue ActiveRecord::RecordNotDestroyed
      redirect_to admin_stays_path, alert: "Не удалось удалить бронь"
    end

    def confirm
      transition { @stay.transition_to!("confirmed") }
    end

    def check_in
      transition { @stay.transition_to!("checked_in") }
    end

    def check_out
      transition { @stay.transition_to!("checked_out") }
    end

    def cancel
      transition { @stay.transition_to!("cancelled") }
    end

    def add_payment
      @stay.add_payment!(method: params[:method], amount: params[:amount],
                         paid_at: parse_date_or_now(params[:paid_at]), note: params[:note])
      redirect_to admin_stay_path(@stay), notice: "Оплата добавлена"
    rescue ArgumentError => e
      redirect_to admin_stay_path(@stay), alert: e.message
    end

    def remove_payment
      @stay.remove_payment!(params[:payment_id])
      redirect_to admin_stay_path(@stay), notice: "Оплата удалена"
    end

    def add_service
      @stay.add_service!(name: params[:name], price: params[:price],
                         quantity: params[:quantity], date: parse_date_or_today(params[:date]),
                         note: params[:note])
      redirect_to admin_stay_path(@stay), notice: "Услуга добавлена"
    rescue ArgumentError => e
      redirect_to admin_stay_path(@stay), alert: e.message
    end

    def cancel_service
      @stay.cancel_service!(params[:service_id])
      redirect_to admin_stay_path(@stay), notice: "Услуга отменена"
    end

    private

    def set_stay
      @stay = Stay.includes(:room, :user).find(params[:id])
    end

    def transition
      yield
      redirect_to admin_stay_path(@stay), notice: "Статус обновлён"
    rescue ArgumentError, ActiveRecord::RecordInvalid => e
      redirect_to admin_stay_path(@stay), alert: e.message
    end

    def parse_date_or_now(value)
      value.present? ? Date.parse(value).to_time : Time.current
    rescue Date::Error
      Time.current
    end

    def parse_date_or_today(value)
      value.present? ? Date.parse(value) : Date.current
    rescue Date::Error
      Date.current
    end

    def stay_params
      params.require(:stay).permit(:room_id, :user_id, :check_in, :check_out, :guests_count, :status, :total_price, :notes)
    end
  end
end
