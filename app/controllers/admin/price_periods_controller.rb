module Admin
  class PricePeriodsController < BaseController
    before_action :set_price_period, only: %i[edit update destroy]

    def index
      @price_periods = PricePeriod.order(:starts_on)
    end

    def new
      @price_period = PricePeriod.new
    end

    def create
      @price_period = PricePeriod.new(price_period_params)

      if @price_period.save
        redirect_to_previous admin_price_periods_path, notice: "Период создан."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @price_period.update(price_period_params)
        redirect_to_previous admin_price_periods_path, notice: "Период обновлён."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @price_period.destroy
      redirect_back_or admin_price_periods_path, notice: "Период удалён."
    end

    private

    def set_price_period
      @price_period = PricePeriod.find(params[:id])
    end

    def price_period_params
      params.require(:price_period).permit(:name, :starts_on, :ends_on, :multiplier)
    end
  end
end
