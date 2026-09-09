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
    post epic_pick_path(@public_epic)

    assert_redirected_to root_path
    assert_equal "Sign in with Spotify to continue.", flash[:alert]
  end

  test "POST creates a pick for public epic" do
    assert_difference "Pick.count", 1 do
      post epic_pick_path(@public_epic)
    end

    assert_redirected_to epic_path(@public_epic)
    assert_equal "Epic picked!", flash[:notice]
  end

  test "POST sets current_user as pick owner" do
    post epic_pick_path(@public_epic)

    pick = Pick.last
    assert_equal @user.id, pick.user_id
  end

  test "POST cannot pick private epic" do
    assert_no_difference "Pick.count" do
      post epic_pick_path(@private_epic)
    end

    assert_redirected_to epic_path(@private_epic)
    assert_includes flash[:alert], "Can't pick private Epics"
  end

  test "POST cannot pick own epic" do
    assert_no_difference "Pick.count" do
      post epic_pick_path(@own_epic)
    end

    assert_redirected_to epic_path(@own_epic)
    assert_includes flash[:alert], "Can't pick your own Epic"
  end

  test "POST prevents duplicate pick" do
    post epic_pick_path(@public_epic)
    assert_difference "Pick.count", 0 do
      post epic_pick_path(@public_epic)
    end

    assert_redirected_to epic_path(@public_epic)
    assert_includes flash[:alert], "Already picked!"
  end

  test "GET epic lists who picked" do
    Pick.create!(user: @user, epic: @public_epic)
    bob = User.create!(username: "bob")
    Pick.create!(user: bob, epic: @public_epic)

    get epic_path(@public_epic)

    assert_response :success
    assert_select "p", /2 Picks/
    assert_select "a[href=?]", profile_path(@user), text: "@#{@user.username}"
    assert_select "a[href=?]", profile_path(bob), text: "@bob"
  end

  test "GET epic shows no picker list when nobody picked" do
    get epic_path(@public_epic)

    assert_response :success
    assert_select "p", /0 Picks/
    assert_select "ul li a", count: 0
  end

  # A escolha de produto e listar todo mundo, inclusive perfis privados: a
  # contagem e a lista sempre batem.
  test "GET epic lists pickers with private profiles too" do
    hidden = User.create!(username: "hidden", visibility: :private_profile)
    Pick.create!(user: hidden, epic: @public_epic)

    get epic_path(@public_epic)

    assert_response :success
    assert_select "a[href=?]", profile_path(hidden), text: "@hidden"
  end

  test "GET epic shows pick button only for eligible user" do
    get epic_path(@public_epic)

    assert_response :success
    # O botao agora vem de shared/_pick_button: o label e "Pick".
    assert_select "button", /\APick\z/
  end

  test "GET epic does not show pick button for owner" do
    get epic_path(@own_epic)

    assert_response :success
    assert_select "button", { text: /\APick\z/, count: 0 }
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
    post epic_pick_path(9999)
    assert_response :not_found
  end

  test "Multiple users can pick same epic" do
    post epic_pick_path(@public_epic)

    # post_as ignored the user it received, so the second POST came from the same
    # user and the test passed asserting 0 — the opposite of what its name says.
    sign_in_as(create_signed_in_user(username: "bob"))

    assert_difference "Pick.count", 1 do
      post epic_pick_path(@public_epic)
    end

    assert_equal 2, @public_epic.picks.count
  end

  # DESTROY

  test "DELETE requires authentication" do
    Pick.create!(user: @user, epic: @public_epic)
    delete sign_out_path

    delete epic_pick_path(@public_epic)

    assert_redirected_to root_path
  end

  test "DELETE removes the pick" do
    Pick.create!(user: @user, epic: @public_epic)

    assert_difference "Pick.count", -1 do
      delete epic_pick_path(@public_epic)
    end

    assert_redirected_to epic_path(@public_epic)
    assert_equal "Pick undone.", flash[:notice]
  end

  test "DELETE without an existing pick says so" do
    assert_no_difference "Pick.count" do
      delete epic_pick_path(@public_epic)
    end

    assert_redirected_to epic_path(@public_epic)
    assert_includes flash[:alert], "have not picked"
  end

  test "DELETE only removes the current user's pick" do
    other = create_signed_in_user(username: "bob")
    Pick.create!(user: @user, epic: @public_epic)
    Pick.create!(user: other, epic: @public_epic)

    assert_difference "Pick.count", -1 do
      delete epic_pick_path(@public_epic)
    end

    # The other person's Pick still stands.
    assert Pick.exists?(user: other, epic: @public_epic)
    assert_not Pick.exists?(user: @user, epic: @public_epic)
  end

  test "pick can be redone after unpicking" do
    post epic_pick_path(@public_epic)
    delete epic_pick_path(@public_epic)

    assert_difference "Pick.count", 1 do
      post epic_pick_path(@public_epic)
    end
  end
end
