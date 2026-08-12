class RoomsController < ApplicationController
  layout "public"

  def show
    @room = Room.includes(:category, :amenities, :approved_reviews).find(params[:id])
    @review = Review.new
    @free_window = @room.next_free_window
  end
end
