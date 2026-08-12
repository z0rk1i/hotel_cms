class RoomsController < ApplicationController
  layout "public"

  def show
    @room = Room.includes(:category, :amenities, :approved_reviews).find(params[:id])
    @review = Review.new
  end
end
