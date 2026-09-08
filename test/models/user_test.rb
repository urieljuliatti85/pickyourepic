require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "requires a username" do
    user = User.new(username: nil)

    assert_not user.valid?
    assert_includes user.errors[:username], "can't be blank"
  end

  test "rejects usernames with invalid characters" do
    user = User.new(username: "uriel juliatti")

    assert_not user.valid?
    assert_includes user.errors[:username], "only letters, numbers and underscore"
  end

  test "username is unique regardless of case" do
    User.create!(username: "uriel")
    duplicate = User.new(username: "URIEL")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:username], "has already been taken"
  end

  test "database rejects a duplicate username even when validations are skipped" do
    User.create!(username: "uriel")

    assert_raises ActiveRecord::RecordNotUnique do
      User.new(username: "URIEL").save!(validate: false)
    end
  end

  test "profile is public by default" do
    user = User.create!(username: "uriel")

    assert user.visibility_public_profile?
  end

  test "is identified in urls by username" do
    user = User.create!(username: "uriel")

    assert_equal "uriel", user.to_param
  end
end
