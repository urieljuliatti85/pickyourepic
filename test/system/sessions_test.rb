require "application_system_test_case"

class SessionsTest < ApplicationSystemTestCase
  # The sign in button is the app's only point that redirects off-domain. Turbo
  # intercepts form submits and follows the redirect by fetch, which Spotify
  # refuses on CORS — the click fails silently. An integration test does not
  # catch this: Turbo only exists in the browser.
  test "signing in navigates the browser away from the app" do
    setup_spotify_credentials

    # The destination has to be cross-origin: that is exactly what Turbo cannot
    # follow by fetch. A local destination would pass even with the bug present.
    # This host does not exist (.invalid is reserved for it, RFC 2606), so no
    # request actually leaves — the browser navigates to its own DNS error page,
    # which already proves it left the app on its own.
    stub_method(Spotify::Client, :authorize_url, "https://spotify-oauth.invalid/authorize") do
      visit root_path
      within("main") { click_button "Sign in with Spotify" }

      assert_no_current_path(root_path, wait: 5)
    end
  end

  # The sign out route always worked and the controller tests always called it
  # directly, so nobody noticed when the screen lost the button. This test goes
  # through the interface: it clicks what the user sees.
  test "a signed in user can sign out from the nav" do
    user = create_signed_in_user(username: "uriel")
    sign_in_as(user)

    visit discover_path
    assert_text "@uriel"

    click_button "Sign out"

    assert_text "Signed out."
    assert_no_text "@uriel"
  end

  test "signing in without credentials configured reports it instead of doing nothing" do
    clear_spotify_credentials

    visit root_path
    within("main") { click_button "Sign in with Spotify" }

    assert_text "Spotify integration is not configured."
  end

  private

  def setup_spotify_credentials
    @original_spotify_env = SpotifyStubs::SPOTIFY_CREDENTIALS.keys.index_with { |key| ENV[key] }
    SpotifyStubs::SPOTIFY_CREDENTIALS.each { |key, value| ENV[key] = value }
  end

  def clear_spotify_credentials
    @original_spotify_env = SpotifyStubs::SPOTIFY_CREDENTIALS.keys.index_with { |key| ENV[key] }
    SpotifyStubs::SPOTIFY_CREDENTIALS.each_key { |key| ENV[key] = nil }
  end

  def teardown
    @original_spotify_env&.each { |key, value| ENV[key] = value }
    super
  end
end
