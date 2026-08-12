module Admin
  class ReviewsController < BaseController
    before_action :set_review, only: %i[approve reject destroy]

    def index
      @reviews = Review.includes(:user).includes(:reviewable)
      @reviews = @reviews.where(status: params[:status]) if params[:status].present?
      @reviews = @reviews.ordered
      @reviews = paginate(@reviews)
    end

    def approve
      @review.approved!
      redirect_back_or admin_reviews_path, notice: "Отзыв одобрен."
    end

    def reject
      @review.rejected!
      redirect_back_or admin_reviews_path, notice: "Отзыв отклонён."
    end

    def destroy
      @review.destroy
      redirect_back_or admin_reviews_path, notice: "Отзыв удалён."
    end

    private

    def set_review
      @review = Review.find(params[:id])
    end
  end
end
