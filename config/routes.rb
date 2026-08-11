Rails.application.routes.draw do
  devise_for :administrators, path: "admin", controllers: { sessions: "administrators/sessions" }
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    registrations: "users/registrations",
    sessions: "users/sessions"
  }

  resources :bookings, only: %i[new create show] do
    get :available_rooms, on: :collection
  end
  get "bookings", to: redirect("/account"), as: :bookings_redirect
  resources :service_orders, only: %i[new create] do
    post :cancel, on: :member
  end
  resources :notifications, only: %i[index] do
    patch :read, on: :member
    post :mark_all_read, on: :collection
  end
  get "account", to: "account#show"

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
    resources :service_orders, only: %i[index] do
      member do
        patch :confirm
        patch :cancel
      end
    end
    resources :gallery_images, only: %i[index new create destroy]
  end

  get "pages/:slug", to: "public_site#page", as: :public_page
  get "news/:slug", to: "public_site#news", as: :public_news
  root to: "public_site#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
