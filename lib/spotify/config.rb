module Spotify
  # App credentials and scopes. Knows no domain models.
  module Config
    AUTHORIZE_URL = "https://accounts.spotify.com/authorize".freeze
    TOKEN_URL     = "https://accounts.spotify.com/api/token".freeze
    API_BASE_URL  = "https://api.spotify.com/v1".freeze

    # streaming                   -> Web Playback SDK (the only playback route for
    #                                new apps; see CLAUDE.md § Architecture — Playback)
    # user-modify-playback-state  -> start the track at position_ms (the Epic's start)
    # user-read-playback-state    -> know which device playback is on
    # user-read-email             -> identify the account
    # user-read-private           -> read the `product` field (premium?)
    SCOPES = %w[
      streaming
      user-modify-playback-state
      user-read-playback-state
      user-read-email
      user-read-private
    ].freeze

    class << self
      def client_id     = ENV["SPOTIFY_CLIENT_ID"]
      def client_secret = ENV["SPOTIFY_CLIENT_SECRET"]
      def scope         = SCOPES.join(" ")

      def configured?
        client_id.present? && client_secret.present?
      end
    end
  end
end
