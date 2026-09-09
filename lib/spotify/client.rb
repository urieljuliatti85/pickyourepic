require "net/http"
require "uri"
require "json"
require "base64"

module Spotify
  # Error and AuthError live in their own files (error.rb, auth_error.rb) so that
  # Zeitwerk resolves them without this file having been loaded first.

  # Spotify HTTP client. Isolated from the domain
  # (CLAUDE.md § Architecture — The Spotify boundary): it speaks only HTTP and
  # Hashes, and knows neither User nor SpotifyAccount.
  module Client
    extend self

    # Step 1 of the Authorization Code flow.
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

    # Step 3: exchange the code for tokens.
    def exchange_code(code:, redirect_uri:)
      token_request(
        grant_type: "authorization_code",
        code: code,
        redirect_uri: redirect_uri
      )
    end

    # Refreshes an expired access_token. Spotify may or may not return a new
    # refresh_token; when it does not, the previous one stays valid.
    def refresh_token(refresh_token:)
      token_request(
        grant_type: "refresh_token",
        refresh_token: refresh_token
      )
    end

    # The authenticated user's profile. Carries `product`, which says whether Premium is on.
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
      # client_secret goes in the Basic header, never in a body nor in the frontend.
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
        raise error_class.new("Spotify request failed: #{response.code}", status: response.code.to_i)
      end

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise error_class, "Spotify returned invalid JSON: #{e.message}"
    end
  end
end
