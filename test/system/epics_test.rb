require "application_system_test_case"

class EpicsTest < ApplicationSystemTestCase
  def setup
    @user = create_signed_in_user
    sign_in_as(@user)
    @track = Track.create!(
      spotify_id: "track_abc",
      name: "Test Song",
      artist_name: "Test Artist",
      duration_ms: 300_000
    )
  end

  test "User can create an epic" do
    visit new_epic_path(track_id: @track.spotify_id)

    fill_in "Title", with: "My Epic"
    fill_in "Description", with: "Great breakdown"
    fill_in "Start time (ms)", with: "60000"
    fill_in "End time (ms)", with: "120000"
    choose "Public"
    click_button "Create Epic"

    assert_text "Epic was successfully created"
    assert_text "My Epic"
    assert_text "1:00 - 2:00"
  end

  test "Invalid timestamps show error" do
    visit new_epic_path(track_id: @track.spotify_id)

    fill_in "Title", with: "Invalid Epic"
    fill_in "Start time (ms)", with: "100000"
    fill_in "End time (ms)", with: "50000"  # Invalid
    click_button "Create Epic"

    assert_text "must be greater than start_time"
  end

  test "User cannot create epic for other's track without permission" do
    other_user = User.create!(username: "other")
    other_track = Track.create!(
      spotify_id: "other_track",
      name: "Other Track",
      artist_name: "Other Artist",
      duration_ms: 300_000
    )

    visit new_epic_path(track_id: other_track.spotify_id)

    fill_in "Title", with: "My Epic"
    fill_in "Start time (ms)", with: "60000"
    fill_in "End time (ms)", with: "120000"
    choose "Public"
    click_button "Create Epic"

    assert_text "Epic was successfully created"

    # O dono e quem esta logado, nao quem criou a Track.
    epic = Epic.last
    assert_equal @user.id, epic.user_id
  end
end
