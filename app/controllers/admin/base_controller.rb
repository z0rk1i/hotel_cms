module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :authenticate_administrator!

    include Pagy::Backend

    private

    def paginate(scope, default_per = 25)
      @pagy, items = pagy(scope, items: default_per)
      items
    end
  end
end
