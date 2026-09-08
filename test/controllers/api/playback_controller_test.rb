require "test_helper"

class Api::PlaybackControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create_signed_in_user(username: "uriel")
  end

  test "GET /api/playback_token requires authentication" do
    delete sign_out_path
    get api_playback_token_path, headers: { "Accept" => "application/json" }
    assert_redirected_to root_path
  end

  test "GET /api/playback_token returns error without spotify account" do
    get api_playback_token_path, headers: { "Accept" => "application/json" }
    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_equal "No Spotify account connected", json["error"]
  end

  test "GET /api/playback_token returns error for non-premium" do
    SpotifyAccount.create!(
      user: @user,
      spotify_uid: "spotify_123",
      access_token: "token",
      refresh_token: "refresh",
      product: "free",
      expires_at: 1.hour.from_now
    )

    get api_playback_token_path, headers: { "Accept" => "application/json" }
    assert_response :forbidden

    json = JSON.parse(response.body)
    assert_equal "Spotify Premium is required for playback", json["error"]
  end

  test "GET /api/playback_token returns token for premium user" do
    SpotifyAccount.create!(
      user: @user,
      spotify_uid: "spotify_123",
      access_token: "valid_token",
      refresh_token: "refresh",
      product: "premium",
      expires_at: 1.hour.from_now
    )

    get api_playback_token_path, headers: { "Accept" => "application/json" }
    assert_response :success

    json = JSON.parse(response.body)
    assert json["access_token"].present?
  end

  test "GET /api/playback_token refreshes expired token" do
    account = SpotifyAccount.create!(
      user: @user,
      spotify_uid: "spotify_123",
      access_token: "expired_token",
      refresh_token: "refresh_token",
      product: "premium",
      expires_at: 1.hour.ago
    )

    # Stub the refresh call
    stub_refresh_response = {
      "access_token" => "new_fresh_token",
      "expires_in" => 3600
    }

    Spotify::Client.stub(:refresh_token, stub_refresh_response) do
      get api_playback_token_path, headers: { "Accept" => "application/json" }
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "new_fresh_token", json["access_token"]
  end
end
