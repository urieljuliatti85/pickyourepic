require "application_system_test_case"

class ProfilesTest < ApplicationSystemTestCase
  def setup
    @user = User.create!(username: "uriel", visibility: :public_profile)
    @private_user = User.create!(username: "alice", visibility: :private_profile)
    @track = Track.create!(
      spotify_id: "track_sys",
      name: "System Test Song",
      artist_name: "Test Artist",
      duration_ms: 300_000
    )
    @public_epic = Epic.create!(
      user: @user,
      track: @track,
      title: "Public Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
  end

  test "Visit public profile shows user info and epics" do
    visit profile_path(@user)

    assert_text "uriel"
    assert_text "Public Profile"
    assert_text "Public Epic"
  end

  test "Visit private profile shows private notice" do
    visit profile_path(@private_user)

    assert_text "alice"
    assert_text "This profile is private"
  end

  test "Visit private profile as owner shows content" do
    sign_in_as(@private_user)
    visit profile_path(@private_user)

    assert_text "alice"
    assert_no_text "This profile is private"
  end
end
