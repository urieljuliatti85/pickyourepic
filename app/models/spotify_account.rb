class SpotifyAccount < ApplicationRecord
  # Tokens never sit in clear text in the database (CLAUDE.md § Spotify policy constraints).
  encrypts :access_token
  encrypts :refresh_token

  belongs_to :user

  validates :spotify_uid, presence: true, uniqueness: true

  # Treats the token as expired slightly early, so a request is never sent with
  # one that expires in transit.
  EXPIRY_LEEWAY = 60.seconds

  def token_expired?
    return true if expires_at.blank?

    expires_at <= Time.current + EXPIRY_LEEWAY
  end

  # Premium is a Web Playback SDK requirement; without it a user creates and
  # discovers Epics but cannot play them (CLAUDE.md § Architecture — Playback).
  def premium? = product == "premium"

  # Returns a usable access_token, refreshing when needed.
  # Every API call goes through here instead of reading access_token directly.
  def fresh_access_token!
    return access_token unless token_expired?
    raise Spotify::AuthError, "missing refresh token" if refresh_token.blank?

    tokens = Spotify::Client.refresh_token(refresh_token: refresh_token)

    self.access_token = tokens.fetch("access_token")
    # Spotify only sometimes returns the refresh_token; keep the current one when it does not.
    self.refresh_token = tokens["refresh_token"] if tokens["refresh_token"].present?
    self.expires_at = tokens["expires_in"].present? ? Time.current + tokens["expires_in"].to_i.seconds : nil
    save!

    access_token
  end
end
