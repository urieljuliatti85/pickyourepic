require "test_helper"

class EpicShowLayoutTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(username: "owner")
    @track = Track.create!(spotify_id: "sh1", name: "Skin", artist_name: "Flume", duration_ms: 240_000)
    @epic = Epic.create!(user: @owner, track: @track, title: "The Drop",
                         start_time: 60_000, end_time: 180_000, visibility: :public)
  end

  test "signed out visitor sees the epic but no pick button" do
    get epic_path(@epic)

    assert_response :success
    assert_select "h1", "The Drop"
    assert_select "form[action=?]", epic_pick_path(@epic), false
  end

  test "owner does not see a pick button on their own epic" do
    sign_in_as(@owner)
    get epic_path(@epic)

    assert_response :success
    assert_select "form[action=?]", epic_pick_path(@epic), false
  end

  test "another user sees the pick button" do
    sign_in_as(User.create!(username: "other"))
    get epic_path(@epic)

    assert_response :success
    assert_select "form[action=?]", epic_pick_path(@epic)
  end

  test "private epic shows no pick button to its owner" do
    @epic.update!(visibility: :private)
    sign_in_as(@owner)
    get epic_path(@epic)

    assert_response :success
    assert_select "h1", "The Drop"
    assert_select "form[action=?]", epic_pick_path(@epic), false
  end
end
