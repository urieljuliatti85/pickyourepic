require "test_helper"

class SpotifyAuthenticationTest < ActiveSupport::TestCase
  test "creates a user and a spotify account on first sign in" do
    user = nil

    assert_difference [ "User.count", "SpotifyAccount.count" ], 1 do
      user = SpotifyAuthentication.call(profile: spotify_profile, tokens: spotify_tokens)
    end

    assert_equal "uriel", user.username
    assert_equal "Uriel", user.display_name
    assert_equal "https://i.scdn.co/image/abc", user.avatar_url

    account = user.spotify_account
    assert_equal "spotify_uid_123", account.spotify_uid
    assert_equal "uriel@example.com", account.email
    assert_equal "access_token_abc", account.access_token
    assert_equal "refresh_token_xyz", account.refresh_token
    assert account.premium?
    assert_in_delta 3600, account.expires_at - Time.current, 5
  end

  test "signing in again reuses the same user and refreshes the token" do
    first = SpotifyAuthentication.call(profile: spotify_profile, tokens: spotify_tokens)

    assert_no_difference [ "User.count", "SpotifyAccount.count" ] do
      second = SpotifyAuthentication.call(
        profile: spotify_profile,
        tokens: spotify_tokens("access_token" => "new_access")
      )
      assert_equal first.id, second.id
    end

    assert_equal "new_access", first.spotify_account.reload.access_token
  end

  test "keeps the existing refresh token when spotify omits it" do
    user = SpotifyAuthentication.call(profile: spotify_profile, tokens: spotify_tokens)

    SpotifyAuthentication.call(
      profile: spotify_profile,
      tokens: spotify_tokens.except("refresh_token")
    )

    assert_equal "refresh_token_xyz", user.spotify_account.reload.refresh_token
  end

  test "derives a unique username when the display name is taken" do
    User.create!(username: "uriel")

    user = SpotifyAuthentication.call(profile: spotify_profile, tokens: spotify_tokens)

    assert_equal "uriel2", user.username
  end

  test "falls back to a default username when the display name has no usable characters" do
    user = SpotifyAuthentication.call(
      profile: spotify_profile("display_name" => "!!!", "id" => "uid_other"),
      tokens: spotify_tokens
    )

    assert_equal "epic", user.username
  end

  test "reflects a downgrade from premium to free" do
    user = SpotifyAuthentication.call(profile: spotify_profile, tokens: spotify_tokens)
    assert user.spotify_account.premium?

    SpotifyAuthentication.call(
      profile: spotify_profile("product" => "free"),
      tokens: spotify_tokens
    )

    assert_not user.spotify_account.reload.premium?
  end
end
