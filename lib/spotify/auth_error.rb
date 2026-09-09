module Spotify
  # Authentication/authorization failure at Spotify: an expired token with no
  # refresh, invalid credentials, a refused OAuth code.
  AuthError = Class.new(Error)
end
