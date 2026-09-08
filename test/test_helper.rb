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

# Fabricas minimas de dominio. Um user so pode ter um Epic por track
# (docs/product.md), entao cada Epic de um mesmo user precisa da sua propria
# Track: o contador garante spotify_id/username unicos sem que cada teste
# tenha que inventar nomes.
module DomainFactories
  def next_sequence
    @sequence = (@sequence || 0) + 1
  end

  def create_track(**overrides)
    n = next_sequence

    Track.create!({
      spotify_id: "track_#{n}",
      name: "Test Song #{n}",
      artist_name: "Test Artist",
      duration_ms: 300_000
    }.merge(overrides))
  end

  def create_user(**overrides)
    User.create!({ username: "user#{next_sequence}" }.merge(overrides))
  end

  # `track:` fica opcional de proposito: quando omitido cada Epic ganha uma
  # Track propria, que e o que respeita a regra de um Epic por user/track.
  def create_epic(user:, track: nil, **overrides)
    Epic.create!({
      user: user,
      track: track || create_track,
      title: "Epic #{next_sequence}",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    }.merge(overrides))
  end
end

class ActiveSupport::TestCase
  include MethodStubbing
  include SpotifyStubs
  include DomainFactories
end

# Atalho para os testes que precisam de um usuario ja autenticado.
module AuthenticationHelpers
  def sign_in_as(user = create_signed_in_user)
    # O login e sempre via Spotify, entao um user criado direto (sem conta
    # ligada) ganha uma aqui em vez de quebrar o helper.
    account = user.spotify_account || SpotifyAccount.create!(
      user: user, spotify_uid: "spotify_uid_#{SecureRandom.hex(6)}",
      product: "premium", access_token: "access", refresh_token: "refresh",
      expires_at: 1.hour.from_now
    )

    state = with_spotify_configured { post auth_spotify_path } &&
      Rack::Utils.parse_query(URI(response.location).query)["state"]

    stub_spotify_oauth(profile: spotify_profile("id" => account.spotify_uid)) do
      get auth_spotify_callback_path(code: "code", state: state)
    end

    user
  end

  # uid default unico: dois users no mesmo teste colidiriam no indice unico de
  # spotify_uid se compartilhassem o valor fixo.
  def create_signed_in_user(username: "uriel", uid: nil, product: "premium")
    uid ||= "spotify_uid_#{SecureRandom.hex(6)}"
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
