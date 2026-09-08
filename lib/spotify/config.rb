module Spotify
  # Credenciais e escopos do app. Nao conhece models de dominio.
  module Config
    AUTHORIZE_URL = "https://accounts.spotify.com/authorize".freeze
    TOKEN_URL     = "https://accounts.spotify.com/api/token".freeze
    API_BASE_URL  = "https://api.spotify.com/v1".freeze

    # streaming                   -> Web Playback SDK (unica via de reproducao
    #                                para apps novos; ver CLAUDE.md §10)
    # user-modify-playback-state  -> iniciar a faixa em position_ms (o inicio do Epic)
    # user-read-playback-state    -> saber em que device o playback esta
    # user-read-email             -> identificar a conta
    # user-read-private           -> ler o campo `product` (premium?)
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
