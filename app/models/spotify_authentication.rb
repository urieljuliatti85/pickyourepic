# The seam between the Spotify integration and the domain
# (CLAUDE.md § Architecture — The Spotify boundary).
# Takes already-normalized Spotify data and returns a domain User.
class SpotifyAuthentication
  def self.call(profile:, tokens:)
    new(profile:, tokens:).call
  end

  def initialize(profile:, tokens:)
    @profile = profile
    @tokens = tokens
  end

  # Creates or updates User + SpotifyAccount in one transaction: as identity
  # goes, the two records are a single thing (CLAUDE.md § Conventions).
  def call
    SpotifyAccount.transaction do
      account = SpotifyAccount.find_by(spotify_uid: uid)
      account ||= SpotifyAccount.new(spotify_uid: uid, user: build_user)

      account.assign_attributes(
        email: @profile["email"],
        product: @profile["product"],
        access_token: @tokens["access_token"],
        expires_at: expires_at
      )
      # The refresh_token only comes on the first authorization; never overwrite it with nil.
      account.refresh_token = @tokens["refresh_token"] if @tokens["refresh_token"].present?

      account.save!
      account.user
    end
  end

  private

  def uid = @profile.fetch("id")

  def expires_at
    seconds = @tokens["expires_in"]
    seconds.present? ? Time.current + seconds.to_i.seconds : nil
  end

  def build_user
    User.new(
      username: available_username,
      display_name: @profile["display_name"].presence,
      avatar_url: @profile.dig("images", 0, "url")
    )
  end

  # Spotify's display_name is neither unique nor safe as a username, so it is
  # only the starting point for a unique handle in our domain.
  def available_username
    base = @profile["display_name"].to_s.downcase.gsub(/[^a-z0-9_]/, "")
    base = "epic" if base.blank?
    base = base.first(24)

    return base unless User.exists?(username: base)

    suffix = 2
    suffix += 1 while User.exists?(username: "#{base}#{suffix}")
    "#{base}#{suffix}"
  end
end
