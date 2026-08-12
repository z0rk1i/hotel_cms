module Admin
  class ServicesController < BaseController
    before_action :set_service, only: %i[edit update destroy]

    def index
      @services = Service.order(:name)
    end

    def new
      @service = Service.new
    end

    def create
      @service = Service.new(service_params)

      if @service.save
        redirect_to_previous admin_services_path, notice: "Услуга добавлена."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @service.update(service_params)
        redirect_to_previous admin_services_path, notice: "Услуга обновлена."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @service.destroy
      redirect_back_or admin_services_path, notice: "Услуга удалена."
    end

    private

    def set_service
      @service = Service.find(params[:id])
    end

    def service_params
      params.require(:service).permit(:name, :description, :price)
    end
  end
end
