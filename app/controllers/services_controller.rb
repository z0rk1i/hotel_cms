class ServicesController < ApplicationController
  layout "public"

  def show
    @service = Service.find(params[:id])
    @review = Review.new
  end
end
