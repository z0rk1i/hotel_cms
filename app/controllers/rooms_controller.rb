class RoomsController < ApplicationController
  layout "public"

  def show
    @room = Room.includes(:category, :approved_reviews).find(params[:id])
    @review = Review.new
  end
end
