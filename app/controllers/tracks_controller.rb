class TracksController < ApplicationController
  before_action :require_authentication

  # GET /tracks?q=...
  def index
    @query = params[:q].to_s.strip
    @results = @query.present? ? search_tracks : []
  rescue Spotify::Error => e
    Rails.logger.warn("Spotify search failed: #{e.message}")
    @results = []
    flash.now[:alert] = "Spotify search is unavailable right now."
  end

  private

  # Persists every result: the next screen (EpicsController#new) resolves the
  # track by `spotify_id` in the database, so a result is only clickable once the
  # Track exists locally.
  def search_tracks
    Spotify::Search.tracks(
      query: @query,
      access_token: current_user.spotify_account.fresh_access_token!
    ).map { |attributes| Track.upsert_from_spotify!(attributes) }
  end
end
