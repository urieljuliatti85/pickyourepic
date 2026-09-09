require "test_helper"

class EpicArtworkTest < ActionDispatch::IntegrationTest
  setup do
    @art = "https://i.scdn.co/image/abc123"
    @user = sign_in_as
    @track = Track.create!(spotify_id: "art1", name: "Skin", artist_name: "Flume",
                           album_name: "Skin", album_artwork_url: @art, duration_ms: 240_000)
  end

  test "epic show displays the album cover" do
    epic = Epic.create!(user: @user, track: @track, title: "Drop",
                        start_time: 0, end_time: 5_000, visibility: :public)

    get epic_path(epic)

    assert_response :success
    assert_select "img[src=?]", @art
    assert_select "p", /Skin/
  end

  test "new epic form displays the album cover" do
    get new_epic_path(track_id: @track.spotify_id)

    assert_response :success
    assert_select "img[src=?]", @art
  end

  test "a track without artwork renders the placeholder instead of a broken image" do
    bare = Track.create!(spotify_id: "art2", name: "No Art", artist_name: "X", duration_ms: 120_000)
    epic = Epic.create!(user: @user, track: bare, title: "E",
                        start_time: 0, end_time: 5_000, visibility: :public)

    get epic_path(epic)

    assert_response :success
    assert_select "img", false
  end
end
