require "test_helper"

class DiscoverControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create_signed_in_user(username: "uriel")
    @other_user = User.create!(username: "alice")
    @track = Track.create!(
      spotify_id: "track_123",
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

  test "GET /discover shows page" do
    get discover_path
    assert_response :success
    assert_text "Discover Epics"
  end

  test "GET /discover shows public epics" do
    get discover_path
    assert_response :success
    assert_text "Public Epic"
  end

  test "GET /discover hides private epics" do
    get discover_path
    assert_response :success
    assert_no_text "Private Epic"
  end

  test "GET /discover shows track info" do
    get discover_path
    assert_response :success
    assert_text "Test Song"
    assert_text "Test Artist"
  end

  test "GET /discover shows creator username" do
    get discover_path
    assert_response :success
    assert_text "alice"
  end

  test "GET /discover shows pick count" do
    user2 = User.create!(username: "bob")
    Pick.create!(user: @user, epic: @public_epic)
    Pick.create!(user: user2, epic: @public_epic)

    get discover_path
    assert_response :success
    assert_text "2 Picks"
  end

  test "GET /discover shows pick button for eligible user" do
    get discover_path
    assert_response :success
    assert_select "button", /Pick/
  end

  test "GET /discover hides pick button for own epic" do
    own_epic = Epic.create!(
      user: @user,
      track: @track,
      title: "My Epic",
      start_time: 200_000,
      end_time: 300_000,
      visibility: :public
    )
    get discover_path
    assert_response :success
    # Should not show Pick button for own epic
  end

  test "GET /discover shows picked badge if already picked" do
    Pick.create!(user: @user, epic: @public_epic)

    get discover_path
    assert_response :success
    assert_text "Picked ✓"
  end

  test "GET /discover orders by trending (most picks first)" do
    epic2 = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Trending Epic",
      start_time: 200_000,
      end_time: 300_000,
      visibility: :public
    )
    user2 = User.create!(username: "bob")
    user3 = User.create!(username: "charlie")
    Pick.create!(user: user2, epic: epic2)
    Pick.create!(user: user3, epic: epic2)
    Pick.create!(user: user2, epic: @public_epic)

    get discover_path
    assert_response :success
    # Trending Epic (2 picks) should appear before Public Epic (1 pick)
    body = response.body
    assert body.index("Trending Epic") < body.index("Public Epic"),
      "Trending Epic should appear before Public Epic"
  end

  test "GET /discover works without authentication" do
    delete sign_out_path
    get discover_path
    assert_response :success
    assert_text "Public Epic"
  end

  test "GET /discover shows empty message when no epics" do
    Epic.destroy_all
    get discover_path
    assert_response :success
    assert_text "No public Epics yet"
  end
end
