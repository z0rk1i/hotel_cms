Rails.application.routes.draw do
  root "public_site#index"

  # Public site
  get "/gallery" => "public_site#gallery"
  get "/news" => "public_site#news"
  get "/news/:slug" => "public_site#news_article", as: :news_article
  get "/page/:slug" => "public_site#page", as: :page
  get "/privacy" => "public_site#privacy", as: :privacy_policy
  get "/rooms/:id" => "public_site#show", as: :room

  # Public booking flow
  get "/bookings/available_rooms" => "bookings#available_rooms"
  get "/bookings/new" => "bookings#new", as: :new_booking
  post "/bookings" => "bookings#create", as: :bookings

  # Guest stays lookup
  get "/account" => "account#show", as: :account
  get "/account/find" => "account#find", as: :account_find

  # Admin authentication (single User model, role-based)
  devise_for :users, path: "admin", controllers: { sessions: "users/sessions" }

  # Admin area
  namespace :admin do
    root "dashboard#index"

    resources :rooms, except: [ :show ] do
      patch :complete_cleaning, on: :member
      delete "photo/:photo_id", on: :member, action: :destroy_photo, as: :photo
    end

    resources :stays, only: %i[index show new create edit update destroy] do
      member do
        patch :confirm
        patch :check_in
        patch :check_out
        patch :cancel
        post :add_payment
        delete "remove_payment/:payment_id", action: :remove_payment, as: :remove_payment
        post :add_service
        delete "cancel_service/:service_id", action: :cancel_service, as: :cancel_service
      end
    end

    resources :users, only: %i[index show destroy] do
      member do
        post :merge_into
        patch :toggle_vip
      end
    end

    get "/reports" => "reports#show", as: :reports
  end
end
