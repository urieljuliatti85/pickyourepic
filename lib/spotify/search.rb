module Spotify
  # Translates Spotify's search response into hashes the domain understands.
  # No model knows this format (CLAUDE.md § Architecture — The Spotify boundary).
  module Search
    extend self

    # /search refuses any limit above 10 with a 400 "Invalid limit" — the message
    # blames the parameter, but the ceiling belongs to the account: 11 already
    # fails, 10 returns 200 with real results. The docs still say 50; do not
    # follow the docs (CLAUDE.md § Spotify policy constraints: verify the API first).
    MAX_LIMIT = 10

    def tracks(query:, access_token:, limit: MAX_LIMIT)
      return [] if query.blank?

      payload = Client.get(
        "/search",
        access_token: access_token,
        params: { q: query, type: "track", limit: limit.clamp(1, MAX_LIMIT) }
      )

      Array(payload.dig("tracks", "items")).filter_map { |item| normalize(item) }
    end

    # Keeps only the metadata the product uses (CLAUDE.md § Spotify policy constraints).
    # `preview_url` is not read: new apps have had no access to it since 2024-11-27.
    def normalize(item)
      spotify_id = item["id"]
      duration = item["duration_ms"].to_i
      return nil if spotify_id.blank? || duration <= 0

      {
        spotify_id: spotify_id,
        name: item["name"].to_s,
        artist_name: Array(item["artists"]).filter_map { |a| a["name"].presence }.join(", "),
        album_name: item.dig("album", "name"),
        album_artwork_url: smallest_artwork(item.dig("album", "images")),
        duration_ms: duration
      }
    end

    # A menor imagem que sirva: a UI e mobile-first e a lista mostra thumbnails.
    def smallest_artwork(images)
      Array(images).filter_map { |image| image["url"] if image["url"].present? }.last
    end
  end
end
