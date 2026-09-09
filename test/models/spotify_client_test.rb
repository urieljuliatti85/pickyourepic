require "test_helper"

class SpotifyClientTest < ActiveSupport::TestCase
  def authorize_params
    url = with_spotify_configured do
      Spotify::Client.authorize_url(state: "abc", redirect_uri: "http://127.0.0.1:3000/cb")
    end

    Rack::Utils.parse_query(URI(url).query)
  end

  test "the authorize url carries the state and redirect uri" do
    params = authorize_params

    assert_equal "abc", params["state"]
    assert_equal "http://127.0.0.1:3000/cb", params["redirect_uri"]
    assert_equal "code", params["response_type"]
  end

  test "the authorize url asks for every scope the app needs" do
    scopes = authorize_params["scope"].split

    assert_includes scopes, "streaming"
    assert_includes scopes, "user-read-private"
    assert_includes scopes, "playlist-read-private"
  end

  # Spotify skips the consent screen for an app the user already approved and
  # returns a token with the OLD scopes. Adding a scope would then be
  # unreachable: signing out and in again would hand back the same permissions,
  # and the playlist calls would keep answering 403 forever.
  test "the authorize url forces the consent screen" do
    assert_equal "true", authorize_params["show_dialog"]
  end
end
