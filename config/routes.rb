Rails.application.routes.draw do
  root "home#index"

  post "auth/spotify", to: "sessions#create", as: :auth_spotify
  get  "auth/spotify/callback", to: "sessions#callback", as: :auth_spotify_callback
  delete "sign_out", to: "sessions#destroy", as: :sign_out

  resources :tracks, only: :index

  # Playlist browsing is disabled. Spotify closed both halves of it: the genre
  # endpoints (/browse/categories and friends) answer 403 since 2024-11-27, and
  # in development mode only the caller's OWN playlists open — a stranger's
  # contents are refused, which left a screen where most cards did nothing.
  # lib/spotify/playlists.rb and its tests stay, so this is a route away from
  # working if the app ever leaves development mode.
  # resources :playlists, only: [ :index, :show ]
  resources :epics, only: [ :new, :create, :show, :destroy ] do
    # Um user tem no maximo um Pick por Epic, entao o destroy nao precisa de
    # id proprio: o Pick e identificado pelo par (current_user, epic).
    resource :pick, only: [ :create, :destroy ]

    # Mesmo motivo do Pick para ser singular: um Favorite por (user, epic).
    resource :favorite, only: [ :create, :destroy ]
  end
  resources :profiles, only: [ :show ], param: :username
  resources :favorites, only: [ :index ]
  # Everyone's public Collections. It sits outside `resources :collections`,
  # which is the user's own area and requires signing in — this one is public,
  # like Discover is for Epics. It is declared first so that "discover" is not
  # swallowed by collections#show as an :id.
  get "collections/discover", to: "public_collections#index", as: :public_collections

  resources :collections do
    resources :collection_epics, only: [ :new, :create, :destroy ]
  end
  get "discover", to: "discover#index"


  namespace :api do
    get "playback_token", to: "playback#token"
  end

  # O login real passa pelo OAuth do Spotify, que um system test nao pode
  # percorrer. Esta rota existe SOMENTE em teste e da o atalho equivalente.
  if Rails.env.test?
    post "test_session/:user_id", to: "test_sessions#create", as: :test_session
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions,
  # otherwise 500. Used by load balancers and uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check
end
