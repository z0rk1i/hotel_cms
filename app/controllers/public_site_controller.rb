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
    apply_category_filter
    apply_sort
    @filter_categories = RoomCategory.order(:name)
    @rooms_by_category = @rooms.group_by(&:category_id)
    order_categories_by_price if params[:sort].in?(%w[price_asc price_desc])
  end

  def page
    @page = Page.find_by!(slug: params[:slug])
  end

  def gallery
    @gallery_images = GalleryImage.includes(:image_attachment).order(created_at: :desc)
  end

  def privacy; end

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

  def apply_category_filter
    @rooms = @rooms.where(category_id: params[:category_id]) if params[:category_id].present?
  end

  def apply_sort
    case params[:sort]
    when "price_asc"
      @rooms = @rooms.reorder(price_per_night: :asc)
    when "price_desc"
      @rooms = @rooms.reorder(price_per_night: :desc)
    end
  end

  def order_categories_by_price
    descending = params[:sort] == "price_desc"
    rank = @rooms_by_category.transform_values { |rooms| rooms.map(&:price_per_night).send(descending ? :max : :min) || 0 }
    sign = descending ? -1 : 1
    @categories = @categories.sort_by { |category| [ sign * (rank[category.id] || 0), category.id ] }
  end

  def search_params
    params.permit(:check_in, :check_out, :guests_count, :category_id, :sort)
  end
end
