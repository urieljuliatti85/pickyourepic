require "test_helper"

class CollectionTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(username: "uriel")
    @other_user = User.create!(username: "alice")
    @track = Track.create!(
      spotify_id: "track_123",
      name: "Test Song",
      artist_name: "Test Artist",
      duration_ms: 300_000
    )
  end

  test "is valid with user and title" do
    collection = Collection.new(user: @user, title: "My Collection")
    assert collection.valid?
  end

  test "requires title" do
    collection = Collection.new(user: @user, title: nil)
    assert_not collection.valid?
    assert_includes collection.errors[:title], "can't be blank"
  end

  test "belongs_to user" do
    collection = Collection.create!(user: @user, title: "My Collection")
    assert_equal @user.id, collection.user_id
    assert_equal @user, collection.user
  end

  test "has_many collection_epics" do
    collection = Collection.create!(user: @user, title: "My Collection")
    epic = Epic.create!(
      user: @user,
      track: @track,
      title: "Epic 1",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
    ce = CollectionEpic.create!(collection: collection, epic: epic, position: 0)

    assert_equal 1, collection.collection_epics.count
    assert_equal ce, collection.collection_epics.first
  end

  test "has_many epics through collection_epics" do
    collection = Collection.create!(user: @user, title: "My Collection")
    epic1 = Epic.create!(
      user: @user,
      track: @track,
      title: "Epic 1",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
    epic2 = Epic.create!(
      user: @user,
      track: @track,
      title: "Epic 2",
      start_time: 100_000,
      end_time: 200_000,
      visibility: :public
    )
    CollectionEpic.create!(collection: collection, epic: epic1, position: 0)
    CollectionEpic.create!(collection: collection, epic: epic2, position: 1)

    assert_equal 2, collection.epics.count
    assert_includes collection.epics, epic1
    assert_includes collection.epics, epic2
  end

  test "enum visibility public" do
    collection = Collection.create!(user: @user, title: "My Collection", visibility: :public)
    assert collection.visibility_public?
  end

  test "enum visibility private" do
    collection = Collection.create!(user: @user, title: "My Collection", visibility: :private)
    assert collection.visibility_private?
  end

  test "default visibility is public" do
    collection = Collection.create!(user: @user, title: "My Collection")
    assert collection.visibility_public?
  end

  test "title length validation" do
    collection = Collection.new(user: @user, title: "")
    assert_not collection.valid?
    assert_includes collection.errors[:title], "is too short"
  end

  test "max title length 255" do
    long_title = "a" * 256
    collection = Collection.new(user: @user, title: long_title)
    assert_not collection.valid?
  end

  test "user has_many collections" do
    collection1 = Collection.create!(user: @user, title: "Collection 1")
    collection2 = Collection.create!(user: @user, title: "Collection 2")

    assert_equal 2, @user.collections.count
    assert_includes @user.collections, collection1
    assert_includes @user.collections, collection2
  end

  test "deleting user deletes collections" do
    collection = Collection.create!(user: @user, title: "My Collection")
    user = collection.user

    user.destroy

    assert_not Collection.exists?(collection.id)
  end

  test "deleting collection deletes collection_epics" do
    collection = Collection.create!(user: @user, title: "My Collection")
    epic = Epic.create!(
      user: @user,
      track: @track,
      title: "Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
    ce = CollectionEpic.create!(collection: collection, epic: epic, position: 0)

    collection.destroy

    assert_not CollectionEpic.exists?(ce.id)
  end

  test "collection can contain own public epic" do
    epic = Epic.create!(
      user: @user,
      track: @track,
      title: "My Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
    collection = Collection.create!(user: @user, title: "My Collection")
    ce = CollectionEpic.create(collection: collection, epic: epic, position: 0)

    assert ce.valid?
  end

  test "collection can contain picked epic" do
    other_epic = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Other Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
    pick = Pick.create!(user: @user, epic: other_epic)
    collection = Collection.create!(user: @user, title: "My Collection")
    ce = CollectionEpic.create(collection: collection, epic: other_epic, position: 0)

    assert ce.valid?
  end
end
