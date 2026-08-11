Rails.application.routes.draw do
  devise_for :administrators, path: "admin"

  namespace :admin do
    root to: "dashboard#index"
    resources :room_categories
    resources :rooms do
      get :available, on: :collection
      delete "photo/:photo_id", to: "rooms#destroy_photo", as: :photo
    end
    resources :guests
    resources :bookings do
      member do
        patch :confirm
        patch :check_in
        patch :check_out
        patch :cancel
      end
    end
    resources :pages
    resources :news, only: %i[index new create edit update destroy]
    resources :services
    resources :gallery_images, only: %i[index new create destroy]
  end

  get "pages/:slug", to: "public_site#page", as: :public_page
  root to: "public_site#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
