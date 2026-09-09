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
    # playlist-read-private       -> list the user's playlists at all
    #
    # That last one reads worse than what we do with it. The consent screen calls
    # it "Access your private playlists", but there is no narrower scope: without
    # it BOTH /me/playlists and /users/{id}/playlists answer 403, including for
    # public ones — the reference claims otherwise, and the API disagrees
    # (checked against a live token, per CLAUDE.md § Spotify policy constraints).
    # Spotify::Playlists therefore keeps only the public ones, so what the app
    # holds stays narrower than what it had to ask for.
    SCOPES = %w[
      streaming
      user-modify-playback-state
      user-read-playback-state
      user-read-email
      user-read-private
      playlist-read-private
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
