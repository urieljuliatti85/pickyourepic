require "test_helper"

class CollectionEpicsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = sign_in_as(create_signed_in_user(username: "uriel"))
    @other_user = User.create!(username: "alice")
    @track = Track.create!(
      spotify_id: "track_123",
      name: "Test Song",
      artist_name: "Test Artist",
      duration_ms: 300_000
    )
    @collection = Collection.create!(user: @user, title: "My Collection")
    @epic = Epic.create!(
      user: @user,
      track: @track,
      title: "My Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
  end

  # CREATE

  test "POST adds epic to collection" do
    assert_difference "CollectionEpic.count", 1 do
      post collection_collection_epics_path(@collection), params: { epic_id: @epic.id }
    end
    assert_redirected_to collection_path(@collection)
    assert_equal "Epic added to the Collection!", flash[:notice]
  end

  test "POST requires authentication" do
    delete sign_out_path
    post collection_collection_epics_path(@collection), params: { epic_id: @epic.id }
    assert_redirected_to root_path
  end

  test "POST rejects non-owner" do
    other_collection = Collection.create!(user: @other_user, title: "Other Col")
    assert_no_difference "CollectionEpic.count" do
      post collection_collection_epics_path(other_collection), params: { epic_id: @epic.id }
    end
    assert_redirected_to collections_path
  end

  test "POST rejects duplicate epic in collection" do
    CollectionEpic.create!(collection: @collection, epic: @epic, position: 0)
    assert_no_difference "CollectionEpic.count" do
      post collection_collection_epics_path(@collection), params: { epic_id: @epic.id }
    end
    assert_redirected_to collection_path(@collection)
    assert_includes flash[:alert], "can only add the same epic once per collection"
  end

  test "POST rejects private epic from another user" do
    private_epic = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Private Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :private
    )
    assert_no_difference "CollectionEpic.count" do
      post collection_collection_epics_path(@collection), params: { epic_id: private_epic.id }
    end
    assert_redirected_to collection_path(@collection)
    assert_includes flash[:alert], "Can't add to collection"
  end

  test "POST can add public epic from other user" do
    other_epic = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Public Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
    assert_difference "CollectionEpic.count", 1 do
      post collection_collection_epics_path(@collection), params: { epic_id: other_epic.id }
    end
  end

  test "POST sets position automatically" do
    post collection_collection_epics_path(@collection), params: { epic_id: @epic.id }
    ce = CollectionEpic.last
    assert_equal 0, ce.position
  end

  # DESTROY

  test "DELETE removes epic from collection" do
    ce = CollectionEpic.create!(collection: @collection, epic: @epic, position: 0)
    assert_difference "CollectionEpic.count", -1 do
      delete collection_collection_epic_path(@collection, ce)
    end
    assert_redirected_to collection_path(@collection)
    assert_equal "Epic removed from the Collection!", flash[:notice]
  end

  test "DELETE rejects non-owner" do
    other_collection = Collection.create!(user: @other_user, title: "Other Col")
    ce = CollectionEpic.create!(collection: other_collection, epic: @epic, position: 0)
    assert_no_difference "CollectionEpic.count" do
      delete collection_collection_epic_path(other_collection, ce)
    end
    assert_redirected_to collections_path
  end
end
