require "test_helper"

class TrackTest < ActiveSupport::TestCase
  def valid_attributes(overrides = {})
    {
      spotify_id: "track_abc", name: "Nocturnal Will", artist_name: "Dödsrit",
      album_name: "Mortal Coil", album_artwork_url: "https://i.scdn.co/image/x",
      duration_ms: 512_000
    }.merge(overrides)
  end

  test "is valid with spotify metadata" do
    assert Track.new(valid_attributes).valid?
  end

  test "requires spotify_id, name and artist" do
    track = Track.new

    assert_not track.valid?
    assert_includes track.errors[:spotify_id], "can't be blank"
    assert_includes track.errors[:name], "can't be blank"
    assert_includes track.errors[:artist_name], "can't be blank"
  end

  test "requires a positive duration" do
    assert_not Track.new(valid_attributes(duration_ms: 0)).valid?
    assert_not Track.new(valid_attributes(duration_ms: -1)).valid?
  end

  test "the database rejects a non positive duration" do
    track = Track.new(valid_attributes(duration_ms: 0))

    assert_raises ActiveRecord::StatementInvalid do
      track.save!(validate: false)
    end
  end

  test "the same song is never duplicated" do
    Track.create!(valid_attributes)

    assert_not Track.new(valid_attributes).valid?
  end

  test "the database rejects a duplicate spotify_id" do
    Track.create!(valid_attributes)

    assert_raises ActiveRecord::RecordNotUnique do
      Track.new(valid_attributes).save!(validate: false)
    end
  end

  test "upsert creates the track once and updates it afterwards" do
    assert_difference "Track.count", 1 do
      Track.upsert_from_spotify!(valid_attributes)
    end

    assert_no_difference "Track.count" do
      track = Track.upsert_from_spotify!(valid_attributes(name: "Nocturnal Will - Remaster"))
      assert_equal "Nocturnal Will - Remaster", track.name
    end
  end

  test "is identified in urls by its spotify id" do
    assert_equal "track_abc", Track.new(valid_attributes).to_param
  end
end
