require "test_helper"

class PickTest < ActiveSupport::TestCase
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

  def valid_attributes(overrides = {})
    epic = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Test Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )

    {
      user: @user,
      epic: epic
    }.merge(overrides)
  end

  test "is valid with user and epic" do
    assert Pick.new(valid_attributes).valid?
  end

  test "requires user_id" do
    pick = Pick.new(valid_attributes(user: nil))

    assert_not pick.valid?
    assert_includes pick.errors[:user_id], "can't be blank"
  end

  test "requires epic_id" do
    pick = Pick.new(valid_attributes(epic: nil))

    assert_not pick.valid?
    assert_includes pick.errors[:epic_id], "can't be blank"
  end

  test "belongs_to user" do
    pick = Pick.create!(valid_attributes)

    assert_equal @user.id, pick.user_id
    assert_equal @user, pick.user
  end

  test "belongs_to epic" do
    epic = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Test Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
    pick = Pick.create!(user: @user, epic: epic)

    assert_equal epic.id, pick.epic_id
    assert_equal epic, pick.epic
  end

  test "user has_many picks" do
    pick1 = Pick.create!(valid_attributes)
    epic2 = Epic.create!(
      user: @other_user,
      track: create_track,
      title: "Another Epic",
      start_time: 100_000,
      end_time: 200_000,
      visibility: :public
    )
    pick2 = Pick.create!(user: @user, epic: epic2)

    assert_equal 2, @user.picks.count
    assert_includes @user.picks, pick1
    assert_includes @user.picks, pick2
  end

  test "epic has_many picks" do
    epic = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Test Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
    user2 = User.create!(username: "bob")

    pick1 = Pick.create!(user: @user, epic: epic)
    pick2 = Pick.create!(user: user2, epic: epic)

    assert_equal 2, epic.picks.count
    assert_includes epic.picks, pick1
    assert_includes epic.picks, pick2
  end

  test "database rejects duplicate user_id + epic_id" do
    epic = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Test Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
    Pick.create!(user: @user, epic: epic)

    duplicate = Pick.new(user: @user, epic: epic)
    assert_raises ActiveRecord::RecordNotUnique do
      duplicate.save!(validate: false)
    end
  end

  test "model validates duplicate user_id + epic_id" do
    epic = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Test Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
    Pick.create!(user: @user, epic: epic)

    duplicate = Pick.new(user: @user, epic: epic)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "can only pick the same epic once"
  end

  test "different users can pick same epic" do
    epic = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Test Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
    user2 = User.create!(username: "bob")

    pick1 = Pick.create!(user: @user, epic: epic)
    pick2 = Pick.create!(user: user2, epic: epic)

    assert_equal 2, epic.picks.count
  end

  test "same user can pick different epics" do
    epic1 = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Epic 1",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )
    epic2 = Epic.create!(
      user: @other_user,
      track: create_track,
      title: "Epic 2",
      start_time: 100_000,
      end_time: 200_000,
      visibility: :public
    )

    pick1 = Pick.create!(user: @user, epic: epic1)
    pick2 = Pick.create!(user: @user, epic: epic2)

    assert_equal 2, @user.picks.count
  end

  test "cannot pick private epic" do
    epic = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Private Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :private
    )

    pick = Pick.new(user: @user, epic: epic)
    assert_not pick.valid?
    assert_includes pick.errors[:epic_id], "cannot pick private epic"
  end

  test "can pick public epic" do
    epic = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Public Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )

    pick = Pick.new(user: @user, epic: epic)
    assert pick.valid?
  end

  test "cannot pick own epic" do
    epic = Epic.create!(
      user: @user,
      track: create_track,
      title: "My Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )

    pick = Pick.new(user: @user, epic: epic)
    assert_not pick.valid?
    assert_includes pick.errors[:epic_id], "cannot pick your own epic"
  end

  test "can pick other user's epic" do
    epic = Epic.create!(
      user: @other_user,
      track: @track,
      title: "Other's Epic",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )

    pick = Pick.new(user: @user, epic: epic)
    assert pick.valid?
  end

  test "deleting user deletes picks" do
    pick = Pick.create!(valid_attributes)
    user = pick.user

    user.destroy

    assert_not Pick.exists?(pick.id)
  end

  test "deleting epic deletes picks" do
    pick = Pick.create!(valid_attributes)
    epic = pick.epic

    epic.destroy

    assert_not Pick.exists?(pick.id)
  end
end
