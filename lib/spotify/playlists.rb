module Spotify
  # Translates Spotify's playlist responses into hashes the domain understands.
  # No model knows this format (CLAUDE.md § Architecture — The Spotify boundary).
  module Playlists
    extend self

    MAX_LIMIT = 50

    # The user's PUBLIC playlists.
    #
    # Reading them needs `playlist-read-private`, which sounds like the opposite
    # of what this returns: without that scope both this endpoint and
    # /me/playlists answer 403 even for public playlists, whatever the reference
    # says (CLAUDE.md § Spotify policy constraints — verified against a live
    # token, not the docs). Since the narrow scope does not exist, the narrowing
    # happens here: a playlist that is not public never leaves this method.
    #
    # /users/{id}/playlists rather than /me/playlists because the id is the
    # `spotify_uid` already on SpotifyAccount, so the same call serves someone
    # else's profile as well as your own.
    def public_for(spotify_uid:, access_token:, limit: MAX_LIMIT)
      return [] if spotify_uid.blank?

      payload = Client.get(
        "/users/#{ERB::Util.url_encode(spotify_uid)}/playlists",
        access_token: access_token,
        params: { limit: limit.clamp(1, MAX_LIMIT) }
      )

      Array(payload["items"])
        .select { |item| item["public"] }
        .filter_map { |item| normalize(item) }
    end

    # Asking for only what we render keeps the response small and makes it
    # explicit that nothing else is read.
    TRACK_FIELDS = "items(track(id,name,duration_ms,artists(name),album(name,images)))".freeze

    # One playlist's tracks, shaped the way Track.upsert_from_spotify! accepts —
    # the same shape the search produces, so a playlist becomes another way into
    # creating an Epic rather than a separate path.
    def tracks(playlist_id:, access_token:, limit: MAX_LIMIT)
      return [] if playlist_id.blank?

      payload = Client.get(
        "/playlists/#{ERB::Util.url_encode(playlist_id)}/tracks",
        access_token: access_token,
        params: { limit: limit.clamp(1, MAX_LIMIT), fields: TRACK_FIELDS }
      )

      # A playlist row can hold a local file or a removed track, and both arrive
      # with a null `track`; Search.normalize rejects whatever is left of them.
      Array(payload["items"]).filter_map { |item| Search.normalize(item["track"] || {}) }
    end

    # Public playlists matching a free-text term.
    #
    # This is deliberately a search and not a genre browse. /browse/categories,
    # /browse/categories/{id}/playlists and /browse/featured-playlists — the
    # endpoints that would give real genre shelves — all answer 403 since
    # Spotify deprecated them on 2024-11-27, the same day preview_url went
    # (CLAUDE.md § Spotify policy constraints; checked against a live token, not
    # the docs). /search is what is left, so the app offers a search rather than
    # pretending to a catalogue it cannot read.
    def search(query:, access_token:, limit: SEARCH_LIMIT)
      return [] if query.blank?

      payload = Client.get(
        "/search",
        access_token: access_token,
        params: { q: query, type: "playlist", limit: limit.clamp(1, SEARCH_LIMIT) }
      )

      # Spotify puts literal nulls among the results — a third of the first page
      # in practice — so compact before anything touches an item.
      Array(payload.dig("playlists", "items"))
        .compact
        .filter_map { |item| normalize(item) }
    end

    # /search answers with the same ceiling as the track search.
    SEARCH_LIMIT = Search::MAX_LIMIT

    def normalize(item)
      id = item["id"]
      return nil if id.blank?

      {
        spotify_id: id,
        name: item["name"].to_s,
        description: item["description"].presence,
        # /search omits the track total that /users/{id}/playlists carries, so
        # this is nil there rather than a made-up zero.
        track_count: item.dig("tracks", "total"),
        artwork_url: largest_artwork(item["images"]),
        spotify_url: item.dig("external_urls", "spotify"),
        owner_name: item.dig("owner", "display_name").presence
      }
    end

    # Unlike a track thumbnail, a playlist cover is rendered large, so here the
    # biggest image is the one worth keeping.
    def largest_artwork(images)
      Array(images).filter_map { |image| image["url"].presence }.first
    end
  end
end
