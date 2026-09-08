module Spotify
  # Falha de autenticacao/autorizacao no Spotify: token expirado sem refresh,
  # credenciais invalidas, code de OAuth recusado.
  AuthError = Class.new(Error)
end
