require "test_helper"

class SpotifyPlaylistsTest < ActiveSupport::TestCase
  def playlist_item(overrides = {})
    {
      "id" => "pl_abc",
      "name" => "Openings that work",
      "description" => "Beginnings that give the song away.",
      "public" => true,
      "tracks" => { "total" => 12 },
      "images" => [
        { "url" => "https://i.scdn.co/image/large" },
        { "url" => "https://i.scdn.co/image/small" }
      ],
      "external_urls" => { "spotify" => "https://open.spotify.com/playlist/pl_abc" }
    }.merge(overrides)
  end

  test "normalizes a playlist into domain metadata" do
    result = Spotify::Playlists.normalize(playlist_item)

    assert_equal "pl_abc", result[:spotify_id]
    assert_equal "Openings that work", result[:name]
    assert_equal "Beginnings that give the song away.", result[:description]
    assert_equal 12, result[:track_count]
    assert_equal "https://open.spotify.com/playlist/pl_abc", result[:spotify_url]
  end

  # A playlist cover is rendered large, unlike a track thumbnail.
  test "keeps the largest artwork" do
    result = Spotify::Playlists.normalize(playlist_item)

    assert_equal "https://i.scdn.co/image/large", result[:artwork_url]
  end

  test "an item with no id is dropped" do
    assert_nil Spotify::Playlists.normalize(playlist_item("id" => nil))
  end

  test "a playlist with no artwork or description still normalizes" do
    result = Spotify::Playlists.normalize(playlist_item("images" => [], "description" => ""))

    assert_equal "pl_abc", result[:spotify_id]
    assert_nil result[:artwork_url]
    assert_nil result[:description]
  end

  # The whole point of the module: the scope we must request is broader than
  # what the app is allowed to show.
  test "a private playlist never leaves public_for" do
    payload = { "items" => [ playlist_item, playlist_item("id" => "pl_secret", "public" => false) ] }

    results = stub_method(Spotify::Client, :get, payload) do
      Spotify::Playlists.public_for(spotify_uid: "user_1", access_token: "token")
    end

    assert_equal [ "pl_abc" ], results.map { |p| p[:spotify_id] }
  end

  # `public` can come back nil for a playlist whose visibility Spotify will not
  # disclose; nil is not public.
  test "a playlist with an unknown visibility is left out" do
    payload = { "items" => [ playlist_item("id" => "pl_unknown", "public" => nil) ] }

    results = stub_method(Spotify::Client, :get, payload) do
      Spotify::Playlists.public_for(spotify_uid: "user_1", access_token: "token")
    end

    assert_empty results
  end

  # stub_method answers with a fixed value, so the calls that need to inspect
  # their own arguments record them here instead.
  def recording_client_get(response)
    calls = []
    singleton = Spotify::Client.singleton_class
    original = Spotify::Client.method(:get)
    singleton.define_method(:get) { |path, **kwargs| calls << [ path, kwargs ]; response }

    begin
      yield
    ensure
      singleton.define_method(:get, original)
    end

    calls
  end

  test "public_for asks for the user's playlists, not /me" do
    calls = recording_client_get({ "items" => [] }) do
      Spotify::Playlists.public_for(spotify_uid: "user_1", access_token: "token")
    end

    assert_equal "/users/user_1/playlists", calls.first.first
  end

  # A uid lands inside a URL path, so it has to be escaped even though it comes
  # from a column rather than a form.
  test "public_for escapes the uid into the path" do
    calls = recording_client_get({ "items" => [] }) do
      Spotify::Playlists.public_for(spotify_uid: "a/b c", access_token: "token")
    end

    assert_equal "/users/a%2Fb%20c/playlists", calls.first.first
  end

  test "public_for returns nothing without a uid" do
    assert_empty Spotify::Playlists.public_for(spotify_uid: nil, access_token: "token")
    assert_empty Spotify::Playlists.public_for(spotify_uid: "", access_token: "token")
  end

  test "public_for clamps the limit to what the endpoint accepts" do
    calls = recording_client_get({ "items" => [] }) do
      Spotify::Playlists.public_for(spotify_uid: "user_1", access_token: "token", limit: 500)
    end

    assert_equal Spotify::Playlists::MAX_LIMIT, calls.first.last[:params][:limit]
  end

  # TRACKS

  def track_row(overrides = {})
    {
      "track" => {
        "id" => "track_1",
        "name" => "Lake Bodom",
        "duration_ms" => 241_800,
        "artists" => [ { "name" => "Children Of Bodom" } ],
        "album" => { "name" => "Hatebreeder", "images" => [ { "url" => "https://i.scdn.co/image/x" } ] }
      }
    }.merge(overrides)
  end

  test "tracks come back in the shape Track.upsert_from_spotify! accepts" do
    payload = { "items" => [ track_row ] }

    results = stub_method(Spotify::Client, :get, payload) do
      Spotify::Playlists.tracks(playlist_id: "pl_abc", access_token: "token")
    end

    assert_equal 1, results.size
    assert_equal "track_1", results.first[:spotify_id]
    assert_equal "Children Of Bodom", results.first[:artist_name]
    assert_equal 241_800, results.first[:duration_ms]
  end

  # A local file or a removed track arrives with a null `track`.
  test "rows without a playable track are dropped" do
    payload = { "items" => [ track_row, { "track" => nil }, { "track" => {} } ] }

    results = stub_method(Spotify::Client, :get, payload) do
      Spotify::Playlists.tracks(playlist_id: "pl_abc", access_token: "token")
    end

    assert_equal [ "track_1" ], results.map { |t| t[:spotify_id] }
  end

  test "tracks returns nothing without a playlist id" do
    assert_empty Spotify::Playlists.tracks(playlist_id: nil, access_token: "token")
  end
end
