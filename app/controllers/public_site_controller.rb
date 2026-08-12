class PublicSiteController < ApplicationController
  layout "public"

  def index
    @amenities = Amenity.order(:name)
    @rooms = Room.with_all_amenities(params[:amenities]).includes(:category, :approved_reviews).order(:floor, :number)
    @categories = RoomCategory.where(id: @rooms.select(:category_id)).order(:name)
    @services = Service.includes(:approved_reviews).order(:name)
    @news = News.published.limit(3)
    @gallery = GalleryImage.includes(:image_attachment).limit(8)
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
end
