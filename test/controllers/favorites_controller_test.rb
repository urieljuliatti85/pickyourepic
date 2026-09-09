require "test_helper"

class FavoritesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = sign_in_as
    @other = User.create!(username: "other")
  end

  def epic_for(user, visibility: :public, id: "f#{SecureRandom.hex(4)}")
    track = Track.create!(spotify_id: id, name: "S", artist_name: "A", duration_ms: 200_000)
    Epic.create!(user: user, track: track, title: "E", start_time: 0, end_time: 5_000, visibility: visibility)
  end

  test "POST favorites an epic" do
    epic = epic_for(@other)

    assert_difference "Favorite.count", 1 do
      post epic_favorite_path(epic)
    end

    assert_redirected_to epic_path(epic)
  end

  test "DELETE removes the favorite" do
    epic = epic_for(@other)
    Favorite.create!(user: @user, epic: epic)

    assert_difference "Favorite.count", -1 do
      delete epic_favorite_path(epic)
    end
  end

  test "a user can favorite their own epic" do
    epic = epic_for(@user)

    assert_difference "Favorite.count", 1 do
      post epic_favorite_path(epic)
    end
  end

  # A validation error would confirm the id exists; a 404 tells nothing.
  test "another user's private epic is not found" do
    epic = epic_for(@other, visibility: :private)

    assert_no_difference "Favorite.count" do
      post epic_favorite_path(epic)
    end

    assert_response :not_found
  end

  test "favoriting twice does not create a second record" do
    epic = epic_for(@other)
    post epic_favorite_path(epic)

    assert_no_difference "Favorite.count" do
      post epic_favorite_path(epic)
    end
  end

  test "GET index lists only the current user's favorites" do
    mine = epic_for(@other, id: "mine")
    theirs = epic_for(@other, id: "theirs")
    Favorite.create!(user: @user, epic: mine)
    Favorite.create!(user: @other, epic: theirs)

    get favorites_path

    assert_response :success
    assert_select "li", 1
  end

  test "favorites require authentication" do
    epic = epic_for(@other)
    delete sign_out_path

    get favorites_path
    assert_redirected_to root_path

    assert_no_difference "Favorite.count" do
      post epic_favorite_path(epic)
    end
  end
end
