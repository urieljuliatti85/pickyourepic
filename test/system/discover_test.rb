require "application_system_test_case"

class DiscoverTest < ApplicationSystemTestCase
  def setup
    @user = create_signed_in_user(username: "uriel")
    sign_in_as(@user)
    @other_user = User.create!(username: "alice")
    @track = Track.create!(
      spotify_id: "track_sys",
      name: "System Test Song",
      artist_name: "Test Artist",
      duration_ms: 300_000
    )
    @public_epic = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Discover Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
  end

  test "User can discover and pick an epic" do
    visit discover_path

    assert_text "Discover Epics"
    assert_text "Discover Epic"
    assert_text "alice"

    click_button "Pick"

    assert_text "Epic picked!"
  end

  test "Discover page shows only public epics" do
    Epic.create!(
      user: @other_user,
      track: create_track,
      title: "Secret Epic",
      start_time: 100_000,
      end_time: 200_000,
      visibility: :private
    )

    visit discover_path

    assert_text "Discover Epic"
    assert_no_text "Secret Epic"
  end
end
