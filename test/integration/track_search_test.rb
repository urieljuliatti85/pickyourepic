require "test_helper"

class TrackSearchTest < ActionDispatch::IntegrationTest
  def spotify_payload
    {
      "tracks" => {
        "items" => [ {
          "id" => "track_abc", "name" => "Nocturnal Will", "duration_ms" => 512_000,
          "artists" => [ { "name" => "Dödsrit" } ],
          "album" => { "name" => "Mortal Coil", "images" => [ { "url" => "https://i.scdn.co/image/s" } ] }
        } ]
      }
    }
  end

  test "search requires authentication" do
    get tracks_path(q: "dödsrit")

    assert_redirected_to root_path
    assert_equal "Sign in with Spotify to continue.", flash[:alert]
  end

  test "an authenticated user sees the track metadata" do
    sign_in_as

    stub_method(Spotify::Client, :get, spotify_payload) do
      get tracks_path(q: "dödsrit")
    end

    assert_response :success
    assert_select "p", text: "Nocturnal Will"
    assert_select "p", text: "Dödsrit"
    assert_match "Mortal Coil", response.body
    assert_match "8:32", response.body
    assert_match "https://i.scdn.co/image/s", response.body
  end

  test "the empty search page does not call spotify" do
    sign_in_as

    stub_method(Spotify::Client, :get, raising: RuntimeError.new("should not search")) do
      get tracks_path
    end

    assert_response :success
  end

  test "a search with no results says so" do
    sign_in_as

    stub_method(Spotify::Client, :get, { "tracks" => { "items" => [] } }) do
      get tracks_path(q: "zzzz")
    end

    assert_response :success
    assert_match "Nenhuma música encontrada", response.body
  end

  test "a spotify outage degrades without breaking the page" do
    sign_in_as

    stub_method(Spotify::Client, :get, raising: Spotify::Error.new("503")) do
      get tracks_path(q: "dödsrit")
    end

    assert_response :success
    assert_match "Spotify search is unavailable right now.", response.body
  end

  test "a search result links to the Epic form and persists the track" do
    sign_in_as

    stub_method(Spotify::Client, :get, spotify_payload) do
      get tracks_path(q: "dödsrit")
    end

    track = Track.find_by(spotify_id: "track_abc")
    assert track, "the searched track should be persisted so the Epic form can find it"
    assert_equal "Nocturnal Will", track.name
    assert_select "a[href=?]", new_epic_path(track_id: "track_abc")
  end

  test "searching the same track twice does not duplicate it" do
    sign_in_as

    2.times do
      stub_method(Spotify::Client, :get, spotify_payload) do
        get tracks_path(q: "dödsrit")
      end
    end

    assert_equal 1, Track.where(spotify_id: "track_abc").count
  end

  test "following a search result reaches the Epic form" do
    sign_in_as

    stub_method(Spotify::Client, :get, spotify_payload) do
      get tracks_path(q: "dödsrit")
    end

    get new_epic_path(track_id: "track_abc")

    assert_response :success
    assert_match "Nocturnal Will", response.body
  end
end
