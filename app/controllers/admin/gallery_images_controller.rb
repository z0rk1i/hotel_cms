module Admin
  class GalleryImagesController < BaseController
    def index
      @gallery_images = GalleryImage.order(created_at: :desc)
    end

    def new
      @gallery_image = GalleryImage.new
    end

    def create
      @gallery_image = GalleryImage.new(gallery_image_params)

      if @gallery_image.save
        redirect_to admin_gallery_images_path, notice: "Изображение добавлено."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @gallery_image = GalleryImage.find(params[:id])
      @gallery_image.destroy
      redirect_to admin_gallery_images_path, notice: "Изображение удалено."
    end

    private

    def gallery_image_params
      params.require(:gallery_image).permit(:title, :image)
    end
  end
end
