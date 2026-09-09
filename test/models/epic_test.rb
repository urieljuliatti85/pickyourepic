require "test_helper"

class EpicTest < ActiveSupport::TestCase
  # user/track sao memoizados: dois Epics do mesmo user na mesma track violam
  # o indice unico, entao os testes que precisam de uma duplicata pedem os
  # mesmos atributos duas vezes de proposito.
  def valid_attributes(overrides = {})
    @default_user ||= create_user(username: "uriel")
    @default_track ||= create_track(
      spotify_id: "track_123", name: "Nocturnal Will", artist_name: "Dödsrit"
    )

    {
      user: @default_user,
      track: @default_track,
      title: "My Epic",
      description: "A great moment",
      start_time: 60_000,
      end_time: 120_000,
      visibility: :public
    }.merge(overrides)
  end

  test "is valid with all attributes" do
    assert Epic.new(valid_attributes).valid?
  end

  test "requires title" do
    epic = Epic.new(valid_attributes(title: nil))

    assert_not epic.valid?
    assert_includes epic.errors[:title], "can't be blank"
  end

  test "rejects empty title" do
    epic = Epic.new(valid_attributes(title: ""))

    assert_not epic.valid?
    assert_includes epic.errors[:title], "is too short (minimum is 1 character)"
  end

  test "title has a maximum length" do
    epic = Epic.new(valid_attributes(title: "x" * 256))

    assert_not epic.valid?
    assert_includes epic.errors[:title], "is too long (maximum is 255 characters)"
  end

  test "requires start_time and end_time" do
    epic = Epic.new(valid_attributes(start_time: nil, end_time: nil))

    assert_not epic.valid?
    assert_includes epic.errors[:start_time], "can't be blank"
    assert_includes epic.errors[:end_time], "can't be blank"
  end

  test "start_time must be an integer" do
    epic = Epic.new(valid_attributes(start_time: 1.5))

    assert_not epic.valid?
    assert_includes epic.errors[:start_time], "must be an integer"
  end

  test "end_time must be an integer" do
    epic = Epic.new(valid_attributes(end_time: 1.5))

    assert_not epic.valid?
    assert_includes epic.errors[:end_time], "must be an integer"
  end

  test "start_time must be >= 0" do
    epic = Epic.new(valid_attributes(start_time: -1))

    assert_not epic.valid?
    assert_includes epic.errors[:start_time], "must be greater than or equal to 0"
  end

  test "end_time must be > start_time" do
    epic = Epic.new(valid_attributes(start_time: 100_000, end_time: 100_000))

    assert_not epic.valid?
    assert_includes epic.errors[:end_time], "must be greater than start_time"
  end

  test "end_time must be > start_time (end_time < start_time)" do
    epic = Epic.new(valid_attributes(start_time: 200_000, end_time: 100_000))

    assert_not epic.valid?
    assert_includes epic.errors[:end_time], "must be greater than start_time"
  end

  test "end_time cannot exceed track duration" do
    epic = Epic.new(valid_attributes(end_time: 400_000))

    assert_not epic.valid?
    assert_includes epic.errors[:end_time], "exceeds track duration"
  end

  test "end_time can equal track duration" do
    epic = Epic.new(valid_attributes(start_time: 100_000, end_time: 300_000))

    assert epic.valid?
  end

  test "belongs to user" do
    epic = Epic.create!(valid_attributes)

    assert_equal "uriel", epic.user.username
  end

  test "belongs to track" do
    epic = Epic.create!(valid_attributes)

    assert_equal "track_123", epic.track.spotify_id
  end

  test "visibility defaults to public" do
    # Without the visibility key: the column's default decides.
    epic = Epic.create!(valid_attributes.except(:visibility))

    assert epic.visibility_public?
  end

  test "visibility can be set to private" do
    epic = Epic.create!(valid_attributes(visibility: :private))

    assert epic.visibility_private?
  end

  test "description is optional" do
    epic = Epic.create!(valid_attributes(description: nil))

    assert_nil epic.description
  end

  test "database rejects start_time < 0" do
    epic = Epic.new(valid_attributes(start_time: -1))

    assert_raises ActiveRecord::StatementInvalid do
      epic.save!(validate: false)
    end
  end

  test "database rejects end_time <= start_time" do
    epic = Epic.new(valid_attributes(start_time: 100_000, end_time: 100_000))

    assert_raises ActiveRecord::StatementInvalid do
      epic.save!(validate: false)
    end
  end

  test "database rejects duplicate (user_id, track_id)" do
    Epic.create!(valid_attributes)
    duplicate = Epic.new(valid_attributes(title: "Different Title"))

    assert_raises ActiveRecord::RecordNotUnique do
      duplicate.save!(validate: false)
    end
  end

  test "user can create epics for different tracks" do
    user = User.create!(username: "alice")
    track1 = Track.create!(
      spotify_id: "track_1",
      name: "Song 1",
      artist_name: "Artist",
      duration_ms: 300_000
    )
    track2 = Track.create!(
      spotify_id: "track_2",
      name: "Song 2",
      artist_name: "Artist",
      duration_ms: 300_000
    )

    epic1 = Epic.create!(
      user: user, track: track1, title: "Epic 1",
      start_time: 10_000, end_time: 20_000
    )
    epic2 = Epic.create!(
      user: user, track: track2, title: "Epic 2",
      start_time: 10_000, end_time: 20_000
    )

    assert_equal 2, user.epics.count
    assert_includes user.epics, epic1
    assert_includes user.epics, epic2
  end

  test "deleting user deletes epics" do
    epic = Epic.create!(valid_attributes)
    user = epic.user

    user.destroy

    assert_not Epic.exists?(epic.id)
  end

  test "deleting track deletes epics" do
    epic = Epic.create!(valid_attributes)
    track = epic.track

    track.destroy

    assert_not Epic.exists?(epic.id)
  end
end
