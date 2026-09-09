require "test_helper"

class PlaylistsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = sign_in_as(create_signed_in_user(username: "uriel"))
  end

  def playlist(overrides = {})
    {
      spotify_id: "pl_1", name: "Rock & Roll", description: nil,
      track_count: 20, artwork_url: nil,
      spotify_url: "https://open.spotify.com/playlist/pl_1", owner_name: "someone"
    }.merge(overrides)
  end

  test "GET /playlists requires authentication" do
    delete sign_out_path
    get playlists_path

    assert_redirected_to root_path
  end

  test "GET /playlists without a term does not call Spotify" do
    called = false

    stub_method(Spotify::Playlists, :search, ->(**) { called = true; [] }) do
      get playlists_path
    end

    assert_response :success
    assert_not called, "a blank search should not reach Spotify"
  end

  test "GET /playlists lists what the search returns" do
    stub_method(Spotify::Playlists, :search, [ playlist ]) do
      get playlists_path(q: "rock")
    end

    assert_response :success
    assert_match "Rock &amp; Roll", response.body
  end

  test "GET /playlists says so when nothing matches" do
    stub_method(Spotify::Playlists, :search, []) do
      get playlists_path(q: "zzzz")
    end

    assert_response :success
    assert_match "No playlists found", response.body
  end

  # The scope was added after people had already signed in, so their token
  # predates it. "Unavailable" would leave them waiting for a fix that only they
  # can perform.
  test "a 403 tells the user to sign in again rather than blaming Spotify" do
    error = Spotify::Error.new("Spotify request failed: 403", status: 403)

    stub_method(Spotify::Playlists, :search, raising: error) do
      get playlists_path(q: "rock")
    end

    assert_response :success
    assert_match "Sign out and in again", response.body
  end

  test "any other Spotify failure reports an outage" do
    error = Spotify::Error.new("Spotify request failed: 500", status: 500)

    stub_method(Spotify::Playlists, :search, raising: error) do
      get playlists_path(q: "rock")
    end

    assert_response :success
    assert_match "Spotify is unavailable", response.body
    assert_no_match "Sign out and in again", response.body
  end

  # A result link lives inside the results turbo-frame, so it has to break out
  # of it: without target="_top" Turbo looks for a "playlist_results" frame in
  # the playlist page, finds none, and renders "Content missing".
  test "a result link navigates out of the results frame" do
    stub_method(Spotify::Playlists, :search, [ playlist ]) do
      get playlists_path(q: "rock")
    end

    assert_response :success
    assert_select "a[href=?][data-turbo-frame=?]", playlist_path("pl_1"), "_top"
  end

  # SHOW

  test "GET /playlists/:id persists the tracks so they can become Epics" do
    attributes = {
      spotify_id: "tr_1", name: "Lake Bodom", artist_name: "Children Of Bodom",
      album_name: "Hatebreeder", album_artwork_url: nil, duration_ms: 241_800
    }

    assert_difference "Track.count", 1 do
      stub_method(Spotify::Playlists, :tracks, [ attributes ]) do
        get playlist_path("pl_1")
      end
    end

    assert_response :success
    assert_match "Lake Bodom", response.body
  end

  # The point of the screen: a playlist is a way into the Epic form.
  test "GET /playlists/:id links each track to the new Epic form" do
    attributes = {
      spotify_id: "tr_2", name: "Everlong", artist_name: "Foo Fighters",
      album_name: "The Colour and the Shape", album_artwork_url: nil, duration_ms: 250_546
    }

    stub_method(Spotify::Playlists, :tracks, [ attributes ]) do
      get playlist_path("pl_1")
    end

    assert_response :success
    assert_select "a[href=?]", new_epic_path(track_id: "tr_2")
  end

  test "GET /playlists/:id survives a playlist we cannot read" do
    error = Spotify::Error.new("Spotify request failed: 403", status: 403)

    stub_method(Spotify::Playlists, :tracks, raising: error) do
      get playlist_path("pl_1")
    end

    assert_response :success
    assert_match "Sign out and in again", response.body
  end

  test "GET /playlists/:id requires authentication" do
    delete sign_out_path
    get playlist_path("pl_1")

    assert_redirected_to root_path
  end
end
