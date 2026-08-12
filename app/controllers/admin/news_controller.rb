module Admin
  class NewsController < BaseController
    before_action :set_news, only: %i[edit update destroy]

    def index
      @news = News.order(published_at: :desc)
    end

    def new
      @news = News.new(published_at: Time.current)
    end

    def create
      @news = News.new(news_params)

      if @news.save
        redirect_to_previous admin_news_index_path, notice: "Новость создана."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @news.update(news_params)
        redirect_to_previous admin_news_index_path, notice: "Новость обновлена."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @news.destroy
      redirect_back_or admin_news_index_path, notice: "Новость удалена."
    end

    private

    def set_news
      @news = News.find(params[:id])
    end

    def news_params
      params.require(:news).permit(:title, :body, :published_at)
    end
  end
end
