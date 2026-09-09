module Spotify
  # Zeitwerk resolves Spotify::Error through this file. Defining the constant
  # inside client.rb left it invisible to anyone who had not loaded
  # Spotify::Client first — the case of SpotifyAccount#fresh_access_token!.
  # `status` carries the HTTP code so callers can tell one failure from another
  # without parsing the message — a 403 on playlists means "re-authorize", which
  # is a different thing to say than "Spotify is down".
  class Error < StandardError
    attr_reader :status

    def initialize(message = nil, status: nil)
      super(message)
      @status = status
    end
  end
end
