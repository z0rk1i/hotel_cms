class PublicSiteController < ApplicationController
  layout "public"

  def index
    @categories = RoomCategory.includes(rooms: :approved_reviews).order(:name)
    @rooms = Room.includes(:category, :approved_reviews).order(:floor, :number)
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
