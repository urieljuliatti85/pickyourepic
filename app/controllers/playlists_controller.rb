class PlaylistsController < ApplicationController
  before_action :require_authentication

  # GET /playlists?q=...
  #
  # A search, not a genre browse. The endpoints that would give real genre
  # shelves (/browse/categories and friends) have answered 403 since Spotify
  # deprecated them on 2024-11-27, so a term is what the API still takes.
  def index
    @query = params[:q].to_s.strip
    @playlists = @query.present? ? search_playlists : []
  rescue Spotify::Error => e
    handle_spotify_failure(e)
    @playlists = []
  end

  # GET /playlists/:id
  #
  # A playlist's songs, as a way into creating an Epic: each track is persisted
  # so the next screen can resolve it by spotify_id, exactly as the track search
  # does.
  def show
    @playlist_id = params[:id].to_s
    @tracks = playlist_tracks
  rescue Spotify::Error => e
    handle_spotify_failure(e)
    @tracks = []
  end

  private

  def search_playlists
    Spotify::Playlists.search(query: @query, access_token: access_token)
  end

  def playlist_tracks
    Spotify::Playlists.tracks(playlist_id: @playlist_id, access_token: access_token)
                      .map { |attributes| Track.upsert_from_spotify!(attributes) }
  end

  def access_token
    current_user.spotify_account.fresh_access_token!
  end

  # A 403 on a playlist's contents is not a passing failure and not something
  # signing in again fixes: Spotify only opens the items of a playlist the user
  # owns or that another person made. One they merely FOLLOW — every editorial
  # playlist included — stays closed, so say that rather than send them round a
  # loop that will not help.
  def handle_spotify_failure(error)
    Rails.logger.warn("Spotify playlists failed: #{error.message}")

    flash.now[:alert] =
      if error.status == 403
        "Spotify does not share this playlist's songs. Try one you made yourself."
      else
        "Spotify is unavailable right now."
      end
  end
end
