# Fronteira entre a integracao Spotify e o dominio
# (CLAUDE.md § Architecture — The Spotify boundary).
# Recebe dados ja normalizados do Spotify e devolve um User do dominio.
class SpotifyAuthentication
  def self.call(profile:, tokens:)
    new(profile:, tokens:).call
  end

  def initialize(profile:, tokens:)
    @profile = profile
    @tokens = tokens
  end

  # Cria ou atualiza User + SpotifyAccount numa transacao: os dois registros
  # sao uma coisa so do ponto de vista de identidade (CLAUDE.md § Conventions).
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
      # O refresh_token so vem na primeira autorizacao; nao sobrescrever com nil.
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

  # O display_name do Spotify nao e unico nem seguro como username, entao e
  # apenas o ponto de partida para um handle unico no nosso dominio.
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
