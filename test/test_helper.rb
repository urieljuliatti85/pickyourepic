ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    fixtures :all
  end
end

# Minitest 6 removeu minitest/mock, entao Object#stub nao existe mais.
# Em vez de adicionar uma gem de mocking (CLAUDE.md §18), um helper minimo:
# troca um metodo por outro e restaura no ensure.
module MethodStubbing
  # `raising:` cobre o caso de simular falha da integracao, ja que o bloco
  # do metodo e usado pelo corpo do teste.
  def stub_method(object, name, value = nil, raising: nil)
    implementation = raising ? ->(*, **) { raise raising } : ->(*, **) { value }
    singleton = object.singleton_class
    original = object.method(name)
    visibility = singleton.private_method_defined?(name) ? :private : :public

    singleton.define_method(name, &implementation)
    singleton.send(:private, name) if visibility == :private

    begin
      yield
    ensure
      singleton.define_method(name, original)
      singleton.send(:private, name) if visibility == :private
    end
  end
end

# Stubs da integracao Spotify. Testes nunca tocam a rede (CLAUDE.md §3: a
# integracao e isolada, entao e substituivel nos testes).
module SpotifyStubs
  SPOTIFY_CREDENTIALS = {
    "SPOTIFY_CLIENT_ID" => "test_client_id",
    "SPOTIFY_CLIENT_SECRET" => "test_client_secret"
  }.freeze

  def with_spotify_configured(&block)
    original = SPOTIFY_CREDENTIALS.keys.index_with { |key| ENV[key] }
    SPOTIFY_CREDENTIALS.each { |key, value| ENV[key] = value }
    yield
  ensure
    original.each { |key, value| ENV[key] = value }
  end

  def spotify_profile(overrides = {})
    {
      "id" => "spotify_uid_123",
      "display_name" => "Uriel",
      "email" => "uriel@example.com",
      "product" => "premium",
      "images" => [ { "url" => "https://i.scdn.co/image/abc" } ]
    }.merge(overrides)
  end

  def spotify_tokens(overrides = {})
    {
      "access_token" => "access_token_abc",
      "refresh_token" => "refresh_token_xyz",
      "expires_in" => 3600
    }.merge(overrides)
  end

  # Substitui as chamadas HTTP do cliente por valores fixos, preservando o
  # resto do fluxo (state, sessao, persistencia) sob teste.
  def stub_spotify_oauth(profile: spotify_profile, tokens: spotify_tokens, &block)
    stub_method(Spotify::Client, :exchange_code, tokens) do
      stub_method(Spotify::Client, :me, profile, &block)
    end
  end
end

class ActiveSupport::TestCase
  include MethodStubbing
  include SpotifyStubs
end

# Atalho para os testes que precisam de um usuario ja autenticado.
module AuthenticationHelpers
  def sign_in_as(user = create_signed_in_user)
    state = with_spotify_configured { post auth_spotify_path } &&
      Rack::Utils.parse_query(URI(response.location).query)["state"]

    stub_spotify_oauth(profile: spotify_profile("id" => user.spotify_account.spotify_uid)) do
      get auth_spotify_callback_path(code: "code", state: state)
    end

    user
  end

  def create_signed_in_user(username: "uriel", uid: "spotify_uid_123", product: "premium")
    user = User.create!(username: username)
    SpotifyAccount.create!(
      user: user, spotify_uid: uid, product: product,
      access_token: "access", refresh_token: "refresh", expires_at: 1.hour.from_now
    )
    user
  end
end

class ActionDispatch::IntegrationTest
  include AuthenticationHelpers
end
