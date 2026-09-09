ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    fixtures :all
  end
end

# Minitest 6 dropped minitest/mock, so Object#stub no longer exists.
# Rather than add a mocking gem (CLAUDE.md § Conventions), a minimal helper:
# it swaps one method for another and restores it in the ensure.
module MethodStubbing
  # `raising:` covers simulating an integration failure, since the method's block
  # is used by the test body.
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

# Spotify integration stubs. Tests never touch the network
# (CLAUDE.md § Architecture — The Spotify boundary: the integration is isolated,
# so it is replaceable in tests).
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

  # Replaces the client's HTTP calls with fixed values, keeping the rest of the
  # flow (state, session, persistence) under test.
  def stub_spotify_oauth(profile: spotify_profile, tokens: spotify_tokens, &block)
    stub_method(Spotify::Client, :exchange_code, tokens) do
      stub_method(Spotify::Client, :me, profile, &block)
    end
  end
end

# Minimal domain factories. A user can only have one Epic per track
# (docs/product.md), so each Epic of the same user needs its own Track: the
# counter keeps spotify_id/username unique without every test having to invent
# names.
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

  # `track:` is optional on purpose: when omitted each Epic gets a Track of its
  # own, which is what honors the one-Epic-per-user/track rule.
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

# Creates the records for a user with a linked Spotify account. It only touches
# models, so it serves integration tests and system tests alike.
module UserFactory
  # A unique default uid: two users in the same test would collide on the
  # spotify_uid unique index if they shared a fixed value.
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

class ActiveSupport::TestCase
  include MethodStubbing
  include SpotifyStubs
  include DomainFactories
  include UserFactory
end

# sign_in_as walks the OAuth flow with the integration HTTP helpers, which
# Capybara does not have: hence it lives apart from UserFactory.
module AuthenticationHelpers
  def sign_in_as(user = create_signed_in_user)
    # Sign-in always goes through Spotify, so a user created directly (with no
    # linked account) gets one here instead of breaking the helper.
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
end

class ActionDispatch::IntegrationTest
  include AuthenticationHelpers
end
