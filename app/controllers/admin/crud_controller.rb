module Admin
  class CrudController < BaseController
    before_action :set_resource, only: %i[edit update destroy]

    def index
      instance_variable_set("@#{controller_name}", index_records)
    end

    def new
      instance_variable_set(model_ivar, new_record)
    end

    def create
      instance_variable_set(model_ivar, model_class.new(resource_params))

      if resource.save
        redirect_to_previous resource_index_path, notice: created_notice
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if resource.update(resource_params)
        redirect_to_previous resource_index_path, notice: updated_notice
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if resource.destroy
        redirect_back_or resource_index_path, notice: destroyed_notice
      else
        redirect_back_or resource_index_path, alert: resource.errors.full_messages.to_sentence
      end
    end

    private

    def set_resource
      instance_variable_set(model_ivar, model_class.find(params[:id]))
    end

    def resource
      instance_variable_get(model_ivar)
    end

    def index_records
      model_class.all
    end

    def new_record
      model_class.new
    end

    def model_ivar
      "@#{controller_name.singularize}"
    end

    def model_class
      raise NotImplementedError, "#{self.class} must implement ##{__method__}"
    end

    def resource_params
      raise NotImplementedError, "#{self.class} must implement ##{__method__}"
    end

    def resource_index_path
      raise NotImplementedError, "#{self.class} must implement ##{__method__}"
    end

    def created_notice
      "Запись создана."
    end

    def updated_notice
      "Запись обновлена."
    end

    def destroyed_notice
      "Запись удалена."
    end
  end
end
