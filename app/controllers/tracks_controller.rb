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

  # Persiste cada resultado: a tela seguinte (EpicsController#new) resolve o
  # track por `spotify_id` no banco, entao um resultado so e clicavel se o
  # Track ja existir localmente.
  def search_tracks
    Spotify::Search.tracks(
      query: @query,
      access_token: current_user.spotify_account.fresh_access_token!
    ).map { |attributes| Track.upsert_from_spotify!(attributes) }
  end
end
