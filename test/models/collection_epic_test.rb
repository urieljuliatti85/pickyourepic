require "test_helper"

class CollectionEpicTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(username: "uriel")
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

  test "is valid with collection, epic, and position" do
    ce = CollectionEpic.new(collection: @collection, epic: @epic, position: 0)
    assert ce.valid?
  end

  test "requires collection_id" do
    ce = CollectionEpic.new(epic: @epic, position: 0)
    assert_not ce.valid?
    assert_includes ce.errors[:collection_id], "can't be blank"
  end

  test "requires epic_id" do
    ce = CollectionEpic.new(collection: @collection, position: 0)
    assert_not ce.valid?
    assert_includes ce.errors[:epic_id], "can't be blank"
  end

  # A coluna tem default 0, entao position so fica em branco se for anulada
  # explicitamente; e esse caso que a validacao de presenca protege.
  test "requires position" do
    ce = CollectionEpic.new(collection: @collection, epic: @epic, position: nil)
    assert_not ce.valid?
    assert_includes ce.errors[:position], "can't be blank"
  end

  test "position defaults to zero" do
    ce = CollectionEpic.create!(collection: @collection, epic: @epic)
    assert_equal 0, ce.position
  end

  test "belongs_to collection" do
    ce = CollectionEpic.create!(collection: @collection, epic: @epic, position: 0)
    assert_equal @collection.id, ce.collection_id
    assert_equal @collection, ce.collection
  end

  test "belongs_to epic" do
    ce = CollectionEpic.create!(collection: @collection, epic: @epic, position: 0)
    assert_equal @epic.id, ce.epic_id
    assert_equal @epic, ce.epic
  end

  test "database enforces unique constraint (collection_id, epic_id)" do
    CollectionEpic.create!(collection: @collection, epic: @epic, position: 0)

    duplicate = CollectionEpic.new(collection: @collection, epic: @epic, position: 1)
    assert_raises ActiveRecord::RecordNotUnique do
      duplicate.save!(validate: false)
    end
  end

  test "model validates unique (collection_id, epic_id)" do
    CollectionEpic.create!(collection: @collection, epic: @epic, position: 0)

    duplicate = CollectionEpic.new(collection: @collection, epic: @epic, position: 1)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:collection_id], "can only add the same epic once per collection"
  end

  test "different collections can have same epic" do
    collection2 = Collection.create!(user: @user, title: "Collection 2")

    ce1 = CollectionEpic.create!(collection: @collection, epic: @epic, position: 0)
    ce2 = CollectionEpic.create!(collection: collection2, epic: @epic, position: 0)

    assert ce1.valid?
    assert ce2.valid?
  end

  test "same collection can have different epics" do
    epic2 = Epic.create!(
      user: @user,
      track: create_track,
      title: "Epic 2",
      start_time: 100_000,
      end_time: 200_000,
      visibility: :public
    )

    ce1 = CollectionEpic.create!(collection: @collection, epic: @epic, position: 0)
    ce2 = CollectionEpic.create!(collection: @collection, epic: epic2, position: 1)

    assert ce1.valid?
    assert ce2.valid?
  end

  test "cannot add private epic from another user" do
    private_epic = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Private Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :private
    )

    ce = CollectionEpic.new(collection: @collection, epic: private_epic, position: 0)
    assert_not ce.valid?
    assert_includes ce.errors[:epic_id], "cannot add private Epic from another user"
  end

  test "can add own private epic" do
    private_epic = Epic.create!(
      user: @user,
      track: create_track,
      title: "My Private Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :private
    )

    ce = CollectionEpic.new(collection: @collection, epic: private_epic, position: 0)
    assert ce.valid?
  end

  test "can add picked public epic" do
    other_epic = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Other Public Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
    Pick.create!(user: @user, epic: other_epic)

    ce = CollectionEpic.new(collection: @collection, epic: other_epic, position: 0)
    assert ce.valid?
  end

  test "epic has_many collection_epics" do
    ce = CollectionEpic.create!(collection: @collection, epic: @epic, position: 0)
    assert_equal 1, @epic.collection_epics.count
    assert_includes @epic.collection_epics, ce
  end

  test "deleting collection deletes collection_epic" do
    ce = CollectionEpic.create!(collection: @collection, epic: @epic, position: 0)
    @collection.destroy

    assert_not CollectionEpic.exists?(ce.id)
  end

  test "deleting epic deletes collection_epic" do
    ce = CollectionEpic.create!(collection: @collection, epic: @epic, position: 0)
    @epic.destroy

    assert_not CollectionEpic.exists?(ce.id)
  end
end
