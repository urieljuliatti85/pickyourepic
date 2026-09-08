require "application_system_test_case"

class PicksTest < ApplicationSystemTestCase
  def setup
    @user = create_signed_in_user(username: "uriel")
    @other_user = User.create!(username: "alice")
    @track = Track.create!(
      spotify_id: "track_abc",
      name: "Test Song",
      artist_name: "Test Artist",
      duration_ms: 300_000
    )
    @public_epic = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Public Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
    @private_epic = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Private Epic",
      start_time: 100_000,
      end_time: 200_000,
      visibility: :private
    )
  end

  test "User can pick an epic from epic page" do
    visit epic_path(@public_epic)

    click_button "Pick this Epic"

    assert_text "Epic foi pickado!"
    assert_text "1 Pick"
  end

  test "User cannot pick private epic" do
    visit epic_path(@private_epic)

    assert_text "Private Epic"
    assert_no_button "Pick this Epic"
  end

  test "User cannot pick own epic" do
    own_epic = Epic.create!(
      user: @user,
      track: @track,
      title: "My Epic",
      start_time: 200_000,
      end_time: 300_000,
      visibility: :public
    )

    visit epic_path(own_epic)

    assert_text "My Epic"
    assert_no_button "Pick this Epic"
  end
end
