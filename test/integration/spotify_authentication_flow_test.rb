require "test_helper"

class SpotifyAuthenticationFlowTest < ActionDispatch::IntegrationTest
  test "starting sign in redirects to spotify with state and scopes" do
    with_spotify_configured do
      post auth_spotify_path
    end

    assert_response :redirect
    location = URI(response.location)
    params = Rack::Utils.parse_query(location.query)

    assert_equal "accounts.spotify.com", location.host
    assert_equal "code", params["response_type"]
    assert_equal "test_client_id", params["client_id"]
    assert_includes params["scope"], "streaming"
    assert params["state"].present?
    assert_equal auth_spotify_callback_url, params["redirect_uri"]
  end

  # Regression: redirect_uri was derived from the request host, so opening the
  # app on localhost produced a URI Spotify does not have registered (it only
  # accepts 127.0.0.1) and sign-in failed with INVALID_CLIENT.
  test "development pins the callback host to 127.0.0.1 regardless of request host" do
    with_spotify_configured do
      stub_method(Rails.env, :development?, true) do
        host! "localhost:3000"
        post auth_spotify_path
      end
    end

    params = Rack::Utils.parse_query(URI(response.location).query)

    assert_equal "http://127.0.0.1:3000/auth/spotify/callback", params["redirect_uri"]
  end

  test "sign in is unavailable when spotify is not configured" do
    stub_method(Spotify::Config, :configured?, false) do
      post auth_spotify_path
    end

    assert_redirected_to root_path
    assert_equal "Spotify integration is not configured.", flash[:alert]
  end

  test "completing the callback signs the user in" do
    state = start_oauth

    assert_difference "User.count", 1 do
      stub_spotify_oauth do
        get auth_spotify_callback_path(code: "valid_code", state: state)
      end
    end

    assert_redirected_to root_path
    assert_equal User.last.id, session[:user_id]
    assert_match "Signed in as @uriel", flash[:notice]
  end

  test "callback with a mismatched state is rejected" do
    start_oauth

    assert_no_difference "User.count" do
      stub_spotify_oauth do
        get auth_spotify_callback_path(code: "valid_code", state: "forged_state")
      end
    end

    assert_redirected_to root_path
    assert_nil session[:user_id]
    assert_equal "Sign in failed. Please try again.", flash[:alert]
  end

  test "callback without a prior authorization request is rejected" do
    assert_no_difference "User.count" do
      stub_spotify_oauth do
        get auth_spotify_callback_path(code: "valid_code", state: "unsolicited")
      end
    end

    assert_nil session[:user_id]
    assert_equal "Sign in failed. Please try again.", flash[:alert]
  end

  test "state cannot be replayed after a successful sign in" do
    state = start_oauth

    stub_spotify_oauth do
      get auth_spotify_callback_path(code: "valid_code", state: state)
    end
    delete sign_out_path

    stub_spotify_oauth do
      get auth_spotify_callback_path(code: "valid_code", state: state)
    end

    assert_nil session[:user_id]
    assert_equal "Sign in failed. Please try again.", flash[:alert]
  end

  test "a denied authorization is reported to the user" do
    state = start_oauth

    get auth_spotify_callback_path(error: "access_denied", state: state)

    assert_redirected_to root_path
    assert_nil session[:user_id]
    assert_equal "Spotify authorization was cancelled.", flash[:alert]
  end

  test "a failing spotify request does not sign the user in" do
    state = start_oauth

    assert_no_difference "User.count" do
      stub_method(Spotify::Client, :exchange_code, raising: Spotify::AuthError.new("401")) do
        get auth_spotify_callback_path(code: "bad_code", state: state)
      end
    end

    assert_nil session[:user_id]
    assert_equal "Sign in failed. Please try again.", flash[:alert]
  end

  test "signing out clears the session" do
    state = start_oauth
    stub_spotify_oauth do
      get auth_spotify_callback_path(code: "valid_code", state: state)
    end
    assert session[:user_id].present?

    delete sign_out_path

    assert_redirected_to root_path
    assert_nil session[:user_id]
    assert_equal "Signed out.", flash[:notice]
  end

  private

  def start_oauth
    with_spotify_configured { post auth_spotify_path }
    Rack::Utils.parse_query(URI(response.location).query)["state"]
  end
end
