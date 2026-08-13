class PublicSiteController < ApplicationController
  def index
    @rooms = Room.order(:number)
    apply_filters
    @rooms_by_category = @rooms.group_by(&:category)
    @categories = ordered_categories
    @filter_categories = Room.order(:category).distinct.pluck(:category)
    @news = StaticContent.news
    @gallery_rooms = Room.includes(photos_attachments: :blob).where.associated(:photos_attachments).order(:number).limit(8)
  end

  def show
    @room = Room.find(params[:id])
    @reviews = @room.approved_reviews
    @free_window = @room.next_free_window
  end

  def gallery
    @rooms = Room.includes(photos_attachments: :blob).order(:number)
  end

  def news
    @news = StaticContent.news
  end

  def news_article
    @article = StaticContent.news(params[:slug])
    raise ActiveRecord::RecordNotFound unless @article
  end

  def page
    @entry = StaticContent.page(params[:slug])
    raise ActiveRecord::RecordNotFound unless @entry
  end

  def privacy
    @entry = StaticContent.page("privacy") || StaticContent.page("about") || {}
  end

  private

  def apply_filters
    @rooms = @rooms.where(category: params[:category]) if params[:category].present?

    amenities = Array(params[:amenities]).map(&:presence).compact
    @rooms = @rooms.where("amenities @> ?::jsonb", amenities.to_json) if amenities.any?

    apply_sort
    apply_availability
  end

  def apply_sort
    direction = params[:sort] == "price_desc" ? :desc : :asc
    @rooms = @rooms.order(price_per_night: direction) if params[:sort].in?(%w[price_asc price_desc])
  end

  def apply_availability
    return unless params[:check_in].present? && params[:check_out].present?

    from = Date.parse(params[:check_in])
    to = Date.parse(params[:check_out])
    guests = params[:guests_count].to_i
    @availability_search = true

    @date_error =
      if to <= from
        "Дата выезда должна быть позже даты заезда"
      elsif from < Date.current
        "Дата заезда не может быть в прошлом"
      end
    return if @date_error

    @rooms = @rooms.select do |room|
      room.capacity >= guests && room.bookable? && room.available_on?(from, to)
    end
  rescue Date::Error
    @date_error = "Неверный формат дат"
  end

  def ordered_categories
    categories = @rooms.map(&:category).uniq
    return categories unless params[:sort].in?(%w[price_asc price_desc])

    key = params[:sort] == "price_desc" ? :max : :min
    grouped = @rooms.group_by(&:category)
    categories.sort_by do |name|
      prices = grouped.fetch(name, []).map(&:price_per_night)
      [ prices.any? ? prices.send(key) : 0, name ]
    end
  end
end
