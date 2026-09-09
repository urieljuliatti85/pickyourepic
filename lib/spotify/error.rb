module Spotify
  # Zeitwerk resolves Spotify::Error through this file. Defining the constant
  # inside client.rb left it invisible to anyone who had not loaded
  # Spotify::Client first — the case of SpotifyAccount#fresh_access_token!.
  Error = Class.new(StandardError)
end
