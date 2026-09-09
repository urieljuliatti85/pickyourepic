require "application_system_test_case"

class PicksTest < ApplicationSystemTestCase
  def setup
    @user = create_signed_in_user(username: "uriel")
    sign_in_as(@user)
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
      track: create_track,
      title: "Private Epic",
      start_time: 100_000,
      end_time: 200_000,
      visibility: :private
    )
  end

  # The point of the turbo_stream: the button swaps without the page reloading. We
  # mark the document before the click; if the mark survives, there was no navigation.
  test "Picking swaps the button without reloading the page" do
    visit epic_path(@public_epic)
    page.execute_script("window.__notReloaded = true")

    click_button "Pick"

    assert_button "Picked ✓"
    assert_text(/1 Pick/i)
    assert page.evaluate_script("window.__notReloaded === true"),
      "a pagina recarregou: o Pick nao passou pelo turbo_stream"
  end

  test "User can pick an epic from epic page" do
    visit epic_path(@public_epic)

    click_button "Pick"

    assert_text "Epic picked!"
    assert_text(/1 Pick/i)
  end

  test "User can unpick an epic from epic page" do
    visit epic_path(@public_epic)
    click_button "Pick"
    assert_text(/1 Pick/i)

    click_button "Picked ✓"

    assert_text "Pick undone."
    assert_text(/0 Picks/i)
    # It offers Pick again, so the user can redo it.
    assert_button "Pick"
  end

  test "Epic page lists who picked and links to their profiles" do
    visit epic_path(@public_epic)
    click_button "Pick"

    assert_text(/1 Pick/i)
    # The nav also has an "@uriel" link, so the lookup happens inside the
    # pickers list.
    within("ul") { click_link "@#{@user.username}" }

    assert_current_path profile_path(@user)
  end

  test "Unpicking from discover keeps the user on discover" do
    visit epic_path(@public_epic)
    click_button "Pick"

    visit discover_path
    click_button "Picked ✓"

    assert_text "Pick undone."
  end

  test "User cannot pick private epic" do
    visit epic_path(@private_epic)

    # The private Epic belongs to another user, so the whole page is denied —
    # stronger than merely hiding the Pick button.
    assert_text "Epic not found."
    assert_no_button "Pick"
  end

  test "User cannot pick own epic" do
    own_epic = Epic.create!(
      user: @user,
      track: create_track,
      title: "My Epic",
      start_time: 200_000,
      end_time: 300_000,
      visibility: :public
    )

    visit epic_path(own_epic)

    assert_text "My Epic"
    assert_no_button "Pick"
  end
end
