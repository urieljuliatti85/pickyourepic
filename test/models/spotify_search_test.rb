require "test_helper"

class SpotifySearchTest < ActiveSupport::TestCase
  def spotify_item(overrides = {})
    {
      "id" => "track_abc",
      "name" => "Nocturnal Will",
      "duration_ms" => 512_000,
      "artists" => [ { "name" => "Dödsrit" } ],
      "album" => {
        "name" => "Mortal Coil",
        "images" => [
          { "url" => "https://i.scdn.co/image/large" },
          { "url" => "https://i.scdn.co/image/small" }
        ]
      }
    }.merge(overrides)
  end

  test "normalizes a spotify track into domain metadata" do
    result = Spotify::Search.normalize(spotify_item)

    assert_equal "track_abc", result[:spotify_id]
    assert_equal "Nocturnal Will", result[:name]
    assert_equal "Dödsrit", result[:artist_name]
    assert_equal "Mortal Coil", result[:album_name]
    assert_equal 512_000, result[:duration_ms]
  end

  test "keeps only metadata, never audio" do
    result = Spotify::Search.normalize(spotify_item)

    assert_equal %i[spotify_id name artist_name album_name album_artwork_url duration_ms].sort,
      result.keys.sort
  end

  test "joins multiple artists" do
    item = spotify_item("artists" => [ { "name" => "Dödsrit" }, { "name" => "Amenra" } ])

    assert_equal "Dödsrit, Amenra", Spotify::Search.normalize(item)[:artist_name]
  end

  test "picks the smallest artwork for a mobile first list" do
    result = Spotify::Search.normalize(spotify_item)

    assert_equal "https://i.scdn.co/image/small", result[:album_artwork_url]
  end

  test "tolerates a track without album images" do
    item = spotify_item("album" => { "name" => "Mortal Coil", "images" => [] })

    assert_nil Spotify::Search.normalize(item)[:album_artwork_url]
  end

  test "discards items without an id or duration" do
    assert_nil Spotify::Search.normalize(spotify_item("id" => nil))
    assert_nil Spotify::Search.normalize(spotify_item("duration_ms" => 0))
  end

  test "a blank query never reaches spotify" do
    assert_equal [], Spotify::Search.tracks(query: "  ", access_token: "token")
  end

  test "maps a search payload into results" do
    payload = { "tracks" => { "items" => [ spotify_item, spotify_item("id" => nil) ] } }

    results = stub_method(Spotify::Client, :get, payload) do
      Spotify::Search.tracks(query: "dödsrit", access_token: "token")
    end

    assert_equal 1, results.size
    assert_equal "track_abc", results.first[:spotify_id]
  end
end
