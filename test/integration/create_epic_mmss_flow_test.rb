require "test_helper"

class CreateEpicMmssFlowTest < ActionDispatch::IntegrationTest
  test "create epic uses MM:SS and stores exact interval" do
    sign_in_as
    track = Track.create!(spotify_id: "sec1", name: "Skin", artist_name: "Flume", duration_ms: 240_000)

    get new_epic_path(track_id: track.spotify_id)
    assert_response :success
    assert_select "h1", "Create Epic"
    assert_select "label", /Start time \(MM:SS\)/
    assert_select "label", /End time \(MM:SS\)/

    post epics_path, params: {
      track_id: track.spotify_id,
      epic: { title: "Drop", start_time_mmss: "0:30", end_time_mmss: "0:45", visibility: "public" }
    }

    epic = Epic.last
    assert_equal 30_000, epic.start_time
    assert_equal 45_000, epic.end_time
    assert_equal 15_000, epic.end_time - epic.start_time
  end

  test "invalid MM:SS re-render keeps the typed value" do
    sign_in_as
    track = Track.create!(spotify_id: "sec2", name: "X", artist_name: "Y", duration_ms: 240_000)

    post epics_path, params: {
      track_id: track.spotify_id,
      epic: { title: "Bad", start_time_mmss: "0:50", end_time_mmss: "0:20", visibility: "public" }
    }

    assert_response :unprocessable_entity
    assert_select "input[name='epic[start_time_mmss]'][value='0:50']"
  end

  test "malformed MM:SS is rejected with a format error" do
    sign_in_as
    track = Track.create!(spotify_id: "sec4", name: "X", artist_name: "Y", duration_ms: 240_000)

    assert_no_difference "Epic.count" do
      post epics_path, params: {
        track_id: track.spotify_id,
        epic: { title: "Bad", start_time_mmss: "90", end_time_mmss: "2:00", visibility: "public" }
      }
    end

    assert_response :unprocessable_entity
    assert_select "#error_explanation", /MM:SS format/
  end

  test "end time beyond track duration is rejected" do
    sign_in_as
    track = Track.create!(spotify_id: "sec3", name: "X", artist_name: "Y", duration_ms: 60_000)

    assert_no_difference "Epic.count" do
      post epics_path, params: {
        track_id: track.spotify_id,
        epic: { title: "Too long", start_time_mmss: "0:10", end_time_mmss: "1:30", visibility: "public" }
      }
    end
  end
end
