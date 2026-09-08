require "net/http"
require "uri"
require "json"
require "base64"

module Spotify
  # Error e AuthError vivem em arquivos proprios (error.rb, auth_error.rb)
  # para que o Zeitwerk os resolva sem depender deste arquivo ter sido lido.

  # Cliente HTTP do Spotify. Isolado do dominio
  # (CLAUDE.md § Architecture — The Spotify boundary): fala apenas HTTP e
  # Hash, nao conhece User nem SpotifyAccount.
  module Client
    extend self

    # Passo 1 do Authorization Code flow.
    def authorize_url(state:, redirect_uri:)
      params = {
        client_id: Config.client_id,
        response_type: "code",
        redirect_uri: redirect_uri,
        scope: Config.scope,
        state: state
      }

      "#{Config::AUTHORIZE_URL}?#{URI.encode_www_form(params)}"
    end

    # Passo 3: troca o code por tokens.
    def exchange_code(code:, redirect_uri:)
      token_request(
        grant_type: "authorization_code",
        code: code,
        redirect_uri: redirect_uri
      )
    end

    # Renova um access_token expirado. O Spotify pode ou nao devolver um novo
    # refresh_token; quando nao devolve, o anterior continua valido.
    def refresh_token(refresh_token:)
      token_request(
        grant_type: "refresh_token",
        refresh_token: refresh_token
      )
    end

    # Perfil do usuario autenticado. Traz `product`, que diz se ha Premium.
    def me(access_token:)
      get("/me", access_token: access_token)
    end

    def get(path, access_token:, params: {})
      uri = URI("#{Config::API_BASE_URL}#{path}")
      uri.query = URI.encode_www_form(params) if params.any?

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{access_token}"

      perform(uri, request)
    end

    private

    def token_request(**form)
      uri = URI(Config::TOKEN_URL)

      request = Net::HTTP::Post.new(uri)
      # client_secret vai no header Basic, nunca no corpo nem no frontend.
      credentials = Base64.strict_encode64("#{Config.client_id}:#{Config.client_secret}")
      request["Authorization"] = "Basic #{credentials}"
      request["Content-Type"] = "application/x-www-form-urlencoded"
      request.body = URI.encode_www_form(form)

      perform(uri, request, error_class: AuthError)
    end

    def perform(uri, request, error_class: Error)
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise error_class, "Spotify request failed: #{response.code}"
      end

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise error_class, "Spotify returned invalid JSON: #{e.message}"
    end
  end
end
