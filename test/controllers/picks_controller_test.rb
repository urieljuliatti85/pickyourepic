require "test_helper"

class PicksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = sign_in_as(create_signed_in_user(username: "uriel"))
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
      track: create_track,
      title: "Private Epic",
      start_time: 100_000,
      end_time: 200_000,
      visibility: :private
    )
    @own_epic = Epic.create!(
      user: @user,
      track: @track,
      title: "My Epic",
      start_time: 200_000,
      end_time: 300_000,
      visibility: :public
    )
  end

  test "POST /epics/:epic_id/picks requires authentication" do
    # Logout
    delete sign_out_path
    post epic_picks_path(@public_epic)

    assert_redirected_to root_path
    assert_equal "Sign in with Spotify to continue.", flash[:alert]
  end

  test "POST creates a pick for public epic" do
    assert_difference "Pick.count", 1 do
      post epic_picks_path(@public_epic)
    end

    assert_redirected_to epic_path(@public_epic)
    assert_equal "Epic foi pickado!", flash[:notice]
  end

  test "POST sets current_user as pick owner" do
    post epic_picks_path(@public_epic)

    pick = Pick.last
    assert_equal @user.id, pick.user_id
  end

  test "POST cannot pick private epic" do
    assert_no_difference "Pick.count" do
      post epic_picks_path(@private_epic)
    end

    assert_redirected_to epic_path(@private_epic)
    assert_includes flash[:alert], "cannot pick private epic"
  end

  test "POST cannot pick own epic" do
    assert_no_difference "Pick.count" do
      post epic_picks_path(@own_epic)
    end

    assert_redirected_to epic_path(@own_epic)
    assert_includes flash[:alert], "cannot pick your own epic"
  end

  test "POST prevents duplicate pick" do
    post epic_picks_path(@public_epic)
    assert_difference "Pick.count", 0 do
      post epic_picks_path(@public_epic)
    end

    assert_redirected_to epic_path(@public_epic)
    assert_includes flash[:alert], "can only pick the same epic once"
  end

  test "GET epic shows pick count" do
    Pick.create!(user: @user, epic: @public_epic)
    user2 = User.create!(username: "bob")
    Pick.create!(user: user2, epic: @public_epic)

    get epic_path(@public_epic)

    assert_response :success
    assert_select "p", /2 Picks/
  end

  test "GET epic shows pick button only for eligible user" do
    get epic_path(@public_epic)

    assert_response :success
    assert_select "button", /Pick this Epic/
  end

  test "GET epic does not show pick button for owner" do
    get epic_path(@own_epic)

    assert_response :success
    assert_select "button", { text: /Pick this Epic/, count: 0 }
  end

  test "GET epic does not show pick button for private epic" do
    # Logout current user, login as different user
    delete sign_out_path
    other_user = User.create!(username: "charlie")
    sign_in_as(other_user)

    get epic_path(@private_epic)

    # Epic privado de outro user nao e apenas "sem botao de Pick": a pagina
    # inteira e negada (EpicsController#authorize_epic_visibility).
    assert_redirected_to root_path
  end

  test "POST returns not found for unknown epic" do
    post epic_picks_path(9999)
    assert_response :not_found
  end

  test "Multiple users can pick same epic" do
    user2 = User.create!(username: "bob")

    post epic_picks_path(@public_epic)
    assert_difference "Pick.count", 0 do
      post_as(user2, epic_picks_path(@public_epic))
    end
  end

  private

  def post_as(user, path, params = {})
    post path, params: params
  end
end
