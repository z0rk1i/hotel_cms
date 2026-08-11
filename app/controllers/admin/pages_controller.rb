module Admin
  class PagesController < BaseController
    before_action :set_page, only: %i[edit update destroy]

    def index
      @pages = Page.order(:slug)
    end

    def new
      @page = Page.new
    end

    def create
      @page = Page.new(page_params)

      if @page.save
        redirect_to admin_pages_path, notice: "Страница создана."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @page.update(page_params)
        redirect_to admin_pages_path, notice: "Страница обновлена."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @page.destroy
      redirect_to admin_pages_path, notice: "Страница удалена."
    end

    private

    def set_page
      @page = Page.find(params[:id])
    end

    def page_params
      params.require(:page).permit(:slug, :title, :body)
    end
  end
end
