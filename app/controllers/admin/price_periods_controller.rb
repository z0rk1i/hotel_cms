module Admin
  class PricePeriodsController < CrudController
    private

    def index_records
      PricePeriod.order(:starts_on)
    end

    def model_class
      PricePeriod
    end

    def resource_params
      params.require(:price_period).permit(:name, :starts_on, :ends_on, :multiplier, :min_nights)
    end

    def resource_index_path
      admin_price_periods_path
    end

    def created_notice
      "Период создан."
    end

    def updated_notice
      "Период обновлён."
    end

    def destroyed_notice
      "Период удалён."
    end
  end
end
