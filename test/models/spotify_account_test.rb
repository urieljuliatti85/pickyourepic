require "test_helper"

class SpotifyAccountTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(username: "uriel")
  end

  test "tokens are encrypted at rest" do
    account = SpotifyAccount.create!(
      user: @user, spotify_uid: "uid_1",
      access_token: "plain_access", refresh_token: "plain_refresh"
    )

    stored = SpotifyAccount.connection.select_one(
      "SELECT access_token, refresh_token FROM spotify_accounts WHERE id = #{account.id}"
    )

    assert_not_equal "plain_access", stored["access_token"]
    assert_not_equal "plain_refresh", stored["refresh_token"]
    assert_equal "plain_access", account.reload.access_token
    assert_equal "plain_refresh", account.reload.refresh_token
  end

  test "spotify_uid is unique" do
    SpotifyAccount.create!(user: @user, spotify_uid: "uid_1")
    other = SpotifyAccount.new(user: User.create!(username: "maria"), spotify_uid: "uid_1")

    assert_not other.valid?
  end

  test "a user has at most one spotify account" do
    SpotifyAccount.create!(user: @user, spotify_uid: "uid_1")

    assert_raises ActiveRecord::RecordNotUnique do
      SpotifyAccount.new(user: @user, spotify_uid: "uid_2").save!(validate: false)
    end
  end

  test "token is expired when it has no expiry" do
    account = SpotifyAccount.new(user: @user, spotify_uid: "uid_1", expires_at: nil)

    assert account.token_expired?
  end

  test "token expiring within the leeway counts as expired" do
    account = SpotifyAccount.new(user: @user, spotify_uid: "uid_1", expires_at: 30.seconds.from_now)

    assert account.token_expired?
  end

  test "token comfortably in the future is not expired" do
    account = SpotifyAccount.new(user: @user, spotify_uid: "uid_1", expires_at: 1.hour.from_now)

    assert_not account.token_expired?
  end

  test "a valid token is returned without contacting spotify" do
    account = SpotifyAccount.create!(
      user: @user, spotify_uid: "uid_1",
      access_token: "still_good", refresh_token: "r", expires_at: 1.hour.from_now
    )

    stub_method(Spotify::Client, :refresh_token, raising: RuntimeError.new("should not refresh")) do
      assert_equal "still_good", account.fresh_access_token!
    end
  end

  test "an expired token is refreshed and persisted" do
    account = SpotifyAccount.create!(
      user: @user, spotify_uid: "uid_1",
      access_token: "expired", refresh_token: "r_old", expires_at: 1.hour.ago
    )

    refreshed = { "access_token" => "brand_new", "refresh_token" => "r_new", "expires_in" => 3600 }

    stub_method(Spotify::Client, :refresh_token, refreshed) do
      assert_equal "brand_new", account.fresh_access_token!
    end

    account.reload
    assert_equal "brand_new", account.access_token
    assert_equal "r_new", account.refresh_token
    assert_not account.token_expired?
  end

  test "refreshing keeps the current refresh token when spotify omits it" do
    account = SpotifyAccount.create!(
      user: @user, spotify_uid: "uid_1",
      access_token: "expired", refresh_token: "r_old", expires_at: 1.hour.ago
    )

    stub_method(Spotify::Client, :refresh_token, { "access_token" => "new", "expires_in" => 3600 }) do
      account.fresh_access_token!
    end

    assert_equal "r_old", account.reload.refresh_token
  end

  test "refreshing without a refresh token fails loudly" do
    account = SpotifyAccount.create!(
      user: @user, spotify_uid: "uid_1", access_token: "expired",
      refresh_token: nil, expires_at: 1.hour.ago
    )

    assert_raises Spotify::AuthError do
      account.fresh_access_token!
    end
  end

  test "premium is derived from the spotify product" do
    account = SpotifyAccount.new(user: @user, spotify_uid: "uid_1", product: "premium")
    assert account.premium?

    account.product = "free"
    assert_not account.premium?
  end
end
