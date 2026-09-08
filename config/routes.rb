Rails.application.routes.draw do
  root "home#index"

  post "auth/spotify", to: "sessions#create", as: :auth_spotify
  get  "auth/spotify/callback", to: "sessions#callback", as: :auth_spotify_callback
  delete "sign_out", to: "sessions#destroy", as: :sign_out

  resources :tracks, only: :index
  resources :epics, only: [:new, :create, :show] do
    resources :picks, only: [:create]
  end
  resources :profiles, only: [:show], param: :username
  resources :collections do
    resources :collection_epics, only: [:create, :destroy]
  end
  get "discover", to: "discover#index"

  namespace :api do
    get "playback_token", to: "playback#token"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions,
  # otherwise 500. Used by load balancers and uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check
end
