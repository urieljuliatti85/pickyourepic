class SpotifyAccount < ApplicationRecord
  # Tokens nunca trafegam em texto claro no banco (CLAUDE.md § Spotify policy constraints).
  encrypts :access_token
  encrypts :refresh_token

  belongs_to :user

  validates :spotify_uid, presence: true, uniqueness: true

  # Considera expirado um pouco antes do prazo real, para não emitir uma
  # requisicao com token que expira em transito.
  EXPIRY_LEEWAY = 60.seconds

  def token_expired?
    return true if expires_at.blank?

    expires_at <= Time.current + EXPIRY_LEEWAY
  end

  # Premium e requisito do Web Playback SDK; sem ele o usuario cria e descobre
  # Epics, mas nao consegue reproduzi-los (CLAUDE.md § Architecture — Playback).
  def premium? = product == "premium"

  # Devolve um access_token utilizavel, renovando quando necessario.
  # Toda chamada a API passa por aqui em vez de ler access_token direto.
  def fresh_access_token!
    return access_token unless token_expired?
    raise Spotify::AuthError, "missing refresh token" if refresh_token.blank?

    tokens = Spotify::Client.refresh_token(refresh_token: refresh_token)

    self.access_token = tokens.fetch("access_token")
    # O Spotify so reenvia o refresh_token as vezes; manter o atual quando nao vem.
    self.refresh_token = tokens["refresh_token"] if tokens["refresh_token"].present?
    self.expires_at = tokens["expires_in"].present? ? Time.current + tokens["expires_in"].to_i.seconds : nil
    save!

    access_token
  end
end
