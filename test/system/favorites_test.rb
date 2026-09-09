require "application_system_test_case"

class FavoritesTest < ApplicationSystemTestCase
  def setup
    @user = create_signed_in_user(username: "uriel")
    sign_in_as(@user)
    @other_user = User.create!(username: "alice")
    @track = Track.create!(spotify_id: "fav_sys", name: "Test Song",
                           artist_name: "Test Artist", duration_ms: 300_000)
    @epic = Epic.create!(user: @other_user, track: @track, title: "Public Epic",
                         start_time: 0, end_time: 100_000, visibility: :public)
  end

  test "User can favorite and unfavorite an epic" do
    visit epic_path(@epic)

    click_button "Favorite"
    assert_text "Epic favorited!"
    assert_button "Favorited"

    click_button "Favorited"
    assert_text "Removed from favorites."
    assert_button "Favorite"
  end

  test "Favorited epics appear on the favorites page" do
    visit epic_path(@epic)
    click_button "Favorite"

    visit favorites_path

    assert_text "Public Epic"
    assert_text "by @alice"
  end

  test "The favorites page explains itself when empty" do
    visit favorites_path

    assert_text "You have not favorited any Epic yet"
  end
end
