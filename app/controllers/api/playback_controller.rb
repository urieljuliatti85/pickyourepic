module Api
  class PlaybackController < ApplicationController
    before_action :require_authentication

    # GET /api/playback_token
    # Returns a fresh access_token for the Web Playback SDK.
    # Requires Premium (CLAUDE.md § Architecture — Playback).
    def token
      spotify_account = current_user.spotify_account

      unless spotify_account
        render json: { error: "No Spotify account connected" }, status: :unprocessable_entity
        return
      end

      unless spotify_account.premium?
        render json: { error: "Spotify Premium is required for playback" }, status: :forbidden
        return
      end

      begin
        access_token = spotify_account.fresh_access_token!
        render json: { access_token: access_token }
      rescue Spotify::AuthError => e
        render json: { error: "Failed to refresh token: #{e.message}" }, status: :unprocessable_entity
      end
    end
  end
end
