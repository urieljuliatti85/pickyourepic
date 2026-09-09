require "test_helper"

class LoggedOutPlaybackTest < ActionDispatch::IntegrationTest
  setup do
    owner = User.create!(username: "owner")
    track = Track.create!(spotify_id: "lo1", name: "Skin", artist_name: "Flume", duration_ms: 240_000)
    @epic = Epic.create!(user: owner, track: track, title: "Drop",
                         start_time: 0, end_time: 5_000, visibility: :public)
  end

  # Playback uses the listener's own Spotify account (Web Playback SDK), so signed
  # out there is nothing to play. What can be fixed is the dead end: the page used
  # to blame the Premium of someone who had not even signed in.
  test "a signed out visitor is offered sign in, not a premium warning" do
    get epic_path(@epic)

    assert_response :success
    assert_select "form[action=?]", auth_spotify_path
    assert_select "button", /Sign in to listen/
    assert_select "p", { text: /Premium is required to play/, count: 0 }
  end

  test "a signed in non-premium user still sees the premium explanation" do
    # sign_in_as walks the real OAuth and the stubbed profile rewrites `product`,
    # so the account only turns free after signing in.
    user = sign_in_as(User.create!(username: "free"))
    user.spotify_account.update!(product: "free")

    get epic_path(@epic)

    assert_response :success
    assert_select "p", /Premium is required to play/
    assert_select "button", { text: /Sign in to listen/, count: 0 }
  end

  test "the playback token is never issued to a signed out visitor" do
    get "/api/playback_token"

    assert_response :redirect
  end
end
