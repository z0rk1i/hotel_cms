module Admin
  class GalleryImagesController < BaseController
    before_action :set_gallery_image, only: %i[edit update destroy]

    def index
      @gallery_images = GalleryImage.order(created_at: :desc)
    end

    def new
      @gallery_image = GalleryImage.new
    end

    def create
      @gallery_image = GalleryImage.new(gallery_image_params)

      if @gallery_image.save
        redirect_to_previous admin_gallery_images_path, notice: "Изображение добавлено."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @gallery_image.update(gallery_image_params)
        redirect_to_previous admin_gallery_images_path, notice: "Изображение обновлено."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @gallery_image.destroy
      redirect_back_or admin_gallery_images_path, notice: "Изображение удалено."
    end

    private

    def set_gallery_image
      @gallery_image = GalleryImage.find(params[:id])
    end

    def gallery_image_params
      params.require(:gallery_image).permit(:title, :image)
    end
  end
end
