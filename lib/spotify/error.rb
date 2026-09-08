module Spotify
  # Zeitwerk resolve Spotify::Error por este arquivo. Definir a constante
  # dentro de client.rb a deixava invisivel para quem nao tivesse carregado
  # Spotify::Client antes — o caso de SpotifyAccount#fresh_access_token!.
  Error = Class.new(StandardError)
end
