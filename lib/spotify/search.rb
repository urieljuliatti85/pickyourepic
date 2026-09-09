module Spotify
  # Traduz a resposta de busca do Spotify para hashes que o dominio entende.
  # Nenhum model conhece este formato (CLAUDE.md § Architecture — The Spotify boundary).
  module Search
    extend self

    # O /search recusa qualquer limit acima de 10 com 400 "Invalid limit" —
    # a mensagem fala do parametro, mas o teto e da conta: 11 ja falha, 10
    # devolve 200 com resultados reais. A doc ainda diz 50; nao siga a doc
    # (CLAUDE.md § Spotify policy constraints: verificar a API antes).
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

    # Guarda apenas os metadados que o produto usa (CLAUDE.md § Spotify policy constraints).
    # `preview_url` nao e lido: apps novos nao tem acesso a ele desde 27/11/2024.
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
