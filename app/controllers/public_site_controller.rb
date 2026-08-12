class PublicSiteController < ApplicationController
  layout "public"

  def index
    @amenities = Amenity.order(:name)
    @rooms = Room.with_all_amenities(params[:amenities]).includes(:category, :amenities, :approved_reviews).order(:floor, :number)
    @categories = RoomCategory.where(id: @rooms.select(:category_id)).order(:name)
    @services = Service.includes(:approved_reviews).order(:name)
    @news = News.published.limit(3)
    @gallery = GalleryImage.includes(:image_attachment).limit(8)

    apply_availability_filter
  end

  def page
    @page = Page.find_by!(slug: params[:slug])
  end

  def gallery
    @gallery_images = GalleryImage.includes(:image_attachment).order(created_at: :desc)
  end

  def news
    @news = News.published.find_by!(slug: params[:slug])
  end

  private

  def apply_availability_filter
    return unless search_params[:check_in].present? || search_params[:check_out].present?

    result = RoomAvailability.new.call(
      check_in: search_params[:check_in],
      check_out: search_params[:check_out]
    )
    return if result.failure?

    @rooms = @rooms.where(id: result.value!.map { |room| room[:id] })
    @rooms = @rooms.where(capacity: (search_params[:guests_count].to_i..)) if search_params[:guests_count].to_i.positive?
    @categories = RoomCategory.where(id: @rooms.select(:category_id)).order(:name)
  end

  def search_params
    params.permit(:check_in, :check_out, :guests_count)
  end
end
