class ReviewsController < ApplicationController
  layout "public"

  before_action :authenticate_user!, only: :create

  def create
    @review = current_user.reviews.new(review_params)
    @review.status = :pending

    if @review.save
      redirect_to reviewable_path(@review), notice: "Отзыв отправлен на модерацию."
    else
      redirect_to reviewable_path(@review, anchor: "reviews"), alert: @review.errors.full_messages.to_sentence
    end
  end

  private

  def review_params
    params.require(:review).permit(:reviewable_type, :reviewable_id, :rating, :body)
  end

  def reviewable_path(review, **options)
    case review.reviewable_type
    when "Room" then room_path(review.reviewable_id, **options)
    when "Service" then service_path(review.reviewable_id, **options)
    else root_path(**options)
    end
  end
end
