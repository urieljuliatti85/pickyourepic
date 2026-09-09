require "test_helper"

class FavoriteTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(username: "owner")
    @other = User.create!(username: "other")
    @track = Track.create!(spotify_id: "fav1", name: "S", artist_name: "A", duration_ms: 200_000)
  end

  def epic_for(user, visibility: :public, spotify_id: nil)
    track = spotify_id ? Track.create!(spotify_id: spotify_id, name: "S", artist_name: "A", duration_ms: 200_000) : @track
    Epic.create!(user: user, track: track, title: "E", start_time: 0, end_time: 5_000, visibility: visibility)
  end

  test "a user can favorite a public epic from someone else" do
    favorite = Favorite.new(user: @other, epic: epic_for(@owner))

    assert favorite.valid?
  end

  # A diferenca central para Pick, que proibe os dois casos abaixo.
  test "a user can favorite their own epic" do
    favorite = Favorite.new(user: @owner, epic: epic_for(@owner))

    assert favorite.valid?
  end

  test "a user can favorite their own private epic" do
    favorite = Favorite.new(user: @owner, epic: epic_for(@owner, visibility: :private))

    assert favorite.valid?
  end

  test "a user cannot favorite a private epic from someone else" do
    favorite = Favorite.new(user: @other, epic: epic_for(@owner, visibility: :private))

    assert_not favorite.valid?
    assert_includes favorite.errors[:epic_id], "cannot favorite private epic from another user"
  end

  test "the same epic cannot be favorited twice by the same user" do
    epic = epic_for(@owner)
    Favorite.create!(user: @other, epic: epic)

    duplicate = Favorite.new(user: @other, epic: epic)

    assert_not duplicate.valid?
  end

  test "the unique index rejects a duplicate that skips validation" do
    epic = epic_for(@owner)
    Favorite.create!(user: @other, epic: epic)

    assert_raises ActiveRecord::RecordNotUnique do
      Favorite.new(user: @other, epic: epic).save!(validate: false)
    end
  end

  test "deleting an epic deletes its favorites" do
    epic = epic_for(@owner)
    Favorite.create!(user: @other, epic: epic)

    assert_difference "Favorite.count", -1 do
      epic.destroy
    end
  end

  test "deleting a user deletes their favorites" do
    Favorite.create!(user: @other, epic: epic_for(@owner))

    assert_difference "Favorite.count", -1 do
      @other.destroy
    end
  end
end
