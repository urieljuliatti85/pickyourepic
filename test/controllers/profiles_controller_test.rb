require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(username: "uriel", visibility: :public_profile)
    @private_user = User.create!(username: "alice", visibility: :private_profile)
    @track = Track.create!(
      spotify_id: "track_123",
      name: "Test Song",
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
    @private_epic = Epic.create!(
      user: @user,
      track: @track,
      title: "Private Epic",
      start_time: 100_000,
      end_time: 200_000,
      visibility: :private
    )
  end

  test "GET /profiles/:username shows profile" do
    get profile_path(@user)

    assert_response :success
    assert_select "h1", /uriel/
  end

  test "GET profile shows public_profile visibility badge" do
    get profile_path(@user)

    assert_response :success
    assert_select "span", /Public Profile/
  end

  test "GET profile shows private_profile visibility badge" do
    get profile_path(@private_user)

    assert_response :success
    assert_select "span", /Private Profile/
  end

  test "GET public profile shows public epics" do
    get profile_path(@user)

    assert_response :success
    assert_select "h2", /Epics/
    assert_text "Public Epic"
  end

  test "GET public profile hides private epics" do
    get profile_path(@user)

    assert_response :success
    assert_no_text "Private Epic"
  end

  test "GET private profile without auth shows notice" do
    get profile_path(@private_user)

    assert_response :success
    assert_text "This profile is private"
  end

  test "GET private profile as owner shows full content" do
    sign_in_as(@private_user)

    get profile_path(@private_user)

    assert_response :success
    assert_no_text "This profile is private"
  end

  test "GET profile shows picked epics" do
    other_user = User.create!(username: "bob", visibility: :public_profile)
    other_epic = Epic.create!(
      user: other_user,
      track: @track,
      title: "Other's Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
    Pick.create!(user: @user, epic: other_epic)

    get profile_path(@user)

    assert_response :success
    assert_select "h2", /Picked Epics/
    assert_text "Other's Epic"
  end

  test "GET profile returns 404 if user not found" do
    assert_raises ActiveRecord::RecordNotFound do
      get profile_path("nonexistent")
    end
  end

  test "GET profile uses username in URL" do
    get "/profiles/uriel"

    assert_response :success
    assert_text "uriel"
  end

  test "GET profile shows pick count on epic" do
    user2 = User.create!(username: "charlie", visibility: :public_profile)
    Pick.create!(user: user2, epic: @public_epic)
    Pick.create!(user: @private_user, epic: @public_epic)

    get profile_path(@user)

    assert_response :success
    assert_text "2 Picks"
  end

  test "GET profile has back link" do
    get profile_path(@user)

    assert_response :success
    assert_select "a", /Back/
  end

  test "GET profile shows public collections" do
    collection = Collection.create!(user: @user, title: "My Playlist", visibility: :public)

    get profile_path(@user)

    assert_response :success
    assert_select "h2", /Collections/
    assert_text "My Playlist"
  end

  test "GET profile hides private collections" do
    Collection.create!(user: @user, title: "Secret Playlist", visibility: :private)

    get profile_path(@user)

    assert_response :success
    assert_no_text "Secret Playlist"
  end

  test "GET profile shows collection epic count" do
    collection = Collection.create!(user: @user, title: "My Playlist", visibility: :public)
    CollectionEpic.create!(collection: collection, epic: @public_epic, position: 0)

    get profile_path(@user)

    assert_response :success
    assert_text "1 Epic"
  end
end
