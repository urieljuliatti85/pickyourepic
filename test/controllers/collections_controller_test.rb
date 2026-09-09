require "test_helper"

class CollectionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = sign_in_as(create_signed_in_user(username: "uriel"))
    @other_user = User.create!(username: "alice")
    @track = Track.create!(
      spotify_id: "track_123",
      name: "Test Song",
      artist_name: "Test Artist",
      duration_ms: 300_000
    )
    @collection = Collection.create!(user: @user, title: "My Collection", visibility: :public)
    @private_collection = Collection.create!(user: @user, title: "Private Col", visibility: :private)
    @other_collection = Collection.create!(user: @other_user, title: "Other Col", visibility: :public)
  end

  # INDEX

  test "GET /collections requires authentication" do
    delete sign_out_path
    get collections_path
    assert_redirected_to root_path
  end

  test "GET /collections lists user collections" do
    get collections_path
    assert_response :success
    assert_match "My Collection", response.body
    assert_match "Private Col", response.body
  end

  test "GET /collections does not show other users collections" do
    get collections_path
    assert_response :success
    assert_no_match "Other Col", response.body
  end

  # NEW

  test "GET /collections/new shows form" do
    get new_collection_path
    assert_response :success
    assert_select "form"
  end

  # CREATE

  test "POST /collections creates collection" do
    assert_difference "Collection.count", 1 do
      post collections_path, params: { collection: { title: "New Col", visibility: "public" } }
    end
    assert_redirected_to collection_path(Collection.last)
    assert_equal "Collection created!", flash[:notice]
  end

  test "POST /collections sets current_user as owner" do
    post collections_path, params: { collection: { title: "New Col" } }
    assert_equal @user.id, Collection.last.user_id
  end

  test "POST /collections rejects missing title" do
    assert_no_difference "Collection.count" do
      post collections_path, params: { collection: { title: "", visibility: "public" } }
    end
    assert_response :unprocessable_entity
  end

  # SHOW

  test "GET /collections/:id shows public collection" do
    get collection_path(@collection)
    assert_response :success
    assert_match "My Collection", response.body
  end

  test "GET /collections/:id shows own private collection" do
    get collection_path(@private_collection)
    assert_response :success
    assert_match "Private Col", response.body
  end

  test "GET other user private collection redirects" do
    other_private = Collection.create!(user: @other_user, title: "Secret", visibility: :private)
    get collection_path(other_private)
    assert_redirected_to collections_path
    assert_equal "Collection not found.", flash[:alert]
  end

  test "GET /collections/:id shows epics in collection" do
    epic = Epic.create!(user: @user, track: @track, title: "My Epic", start_time: 0, end_time: 100_000, visibility: :public)
    CollectionEpic.create!(collection: @collection, epic: epic, position: 0)

    get collection_path(@collection)
    assert_response :success
    assert_match "My Epic", response.body
  end

  # EDIT

  test "GET /collections/:id/edit shows form" do
    get edit_collection_path(@collection)
    assert_response :success
    assert_select "form"
  end

  test "GET /collections/:id/edit rejects non-owner" do
    get edit_collection_path(@other_collection)
    assert_redirected_to collections_path
  end

  # UPDATE

  test "PATCH /collections/:id updates collection" do
    patch collection_path(@collection), params: { collection: { title: "Updated" } }
    assert_redirected_to collection_path(@collection)
    assert_equal "Updated", @collection.reload.title
  end

  test "PATCH /collections/:id rejects non-owner" do
    patch collection_path(@other_collection), params: { collection: { title: "Hacked" } }
    assert_redirected_to collections_path
    assert_equal "Other Col", @other_collection.reload.title
  end

  # DESTROY

  test "DELETE /collections/:id destroys collection" do
    assert_difference "Collection.count", -1 do
      delete collection_path(@collection)
    end
    assert_redirected_to collections_path
  end

  test "DELETE /collections/:id rejects non-owner" do
    assert_no_difference "Collection.count" do
      delete collection_path(@other_collection)
    end
    assert_redirected_to collections_path
  end

  # VISIBILITY

  test "GET /collections/:id shows visibility badge" do
    get collection_path(@collection)
    assert_select "span", /Public/
  end

  test "GET /collections/:id shows edit/delete for owner" do
    get collection_path(@collection)
    assert_select "a", /Edit/
  end

  test "GET /collections/:id hides edit/delete for non-owner" do
    get collection_path(@other_collection)
    assert_response :success
    assert_select "a", { text: /Edit/, count: 0 }
  end

  # PICK NOS CARDS
  #
  # Uma Collection pode conter Epic de outra pessoa, entao o card oferece o
  # Pick; no Epic do proprio dono o partial nao renderiza nada
  # (CLAUDE.md § Authorization).

  test "GET /collections/:id offers Pick on another user's epic" do
    epic = Epic.create!(user: @other_user, track: @track, title: "Alheio",
                        start_time: 0, end_time: 30_000, visibility: :public)
    CollectionEpic.create!(collection: @collection, epic: epic)

    get collection_path(@collection)

    assert_response :success
    assert_select "button[type=submit]", text: "Pick"
  end

  test "GET /collections/:id does not offer Pick on your own epic" do
    epic = Epic.create!(user: @user, track: @track, title: "Meu",
                        start_time: 0, end_time: 30_000, visibility: :public)
    CollectionEpic.create!(collection: @collection, epic: epic)

    get collection_path(@collection)

    assert_response :success
    assert_select "button[type=submit]", { text: "Pick", count: 0 }
  end

  test "GET /collections/:id shows the undo state for an already picked epic" do
    epic = Epic.create!(user: @other_user, track: @track, title: "Ja pickado",
                        start_time: 0, end_time: 30_000, visibility: :public)
    CollectionEpic.create!(collection: @collection, epic: epic)
    Pick.create!(user: @user, epic: epic)

    get collection_path(@collection)

    assert_response :success
    assert_select "button[type=submit]", text: "Picked ✓"
  end
end
