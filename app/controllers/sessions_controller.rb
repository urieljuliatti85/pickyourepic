class SessionsController < ApplicationController
  # The callback arrives from Spotify, an external context: it carries no CSRF
  # token. The equivalent protection is the `state` param, validated below.
  skip_forgery_protection only: :callback

  # POST /auth/spotify — starts the flow. It is POST (not GET) so a third-party
  # link cannot trigger a login.
  def create
    unless Spotify::Config.configured?
      return redirect_to(root_path, alert: "Spotify integration is not configured.")
    end

    state = SecureRandom.hex(24)
    session[:spotify_oauth_state] = state

    redirect_to Spotify::Client.authorize_url(state: state, redirect_uri: callback_url),
      allow_other_host: true
  end

  # GET /auth/spotify/callback
  def callback
    expected_state = session.delete(:spotify_oauth_state)

    if params[:error].present?
      return redirect_to(root_path, alert: "Spotify authorization was cancelled.")
    end

    # Missing or mismatched state => the request did not come from our flow.
    if expected_state.blank? || !ActiveSupport::SecurityUtils.secure_compare(params[:state].to_s, expected_state)
      return redirect_to(root_path, alert: "Sign in failed. Please try again.")
    end

    tokens = Spotify::Client.exchange_code(code: params[:code].to_s, redirect_uri: callback_url)
    profile = Spotify::Client.me(access_token: tokens["access_token"])

    user = SpotifyAuthentication.call(profile: profile, tokens: tokens)
    sign_in(user)

    redirect_to root_path, notice: "Signed in as @#{user.username}."
  rescue Spotify::Error => e
    Rails.logger.warn("Spotify sign-in failed: #{e.message}")
    redirect_to root_path, alert: "Sign in failed. Please try again."
  end

  # DELETE /sign_out
  def destroy
    sign_out
    redirect_to root_path, notice: "Signed out."
  end

  private

  # Spotify matches redirect_uri by exact equality against what the dashboard
  # holds, and rejects `localhost` (only 127.0.0.1 is accepted). Deriving it from
  # the request host breaks sign-in for anyone opening the app on localhost, so
  # in development we pin the registered host.
  def callback_url
    return auth_spotify_callback_url unless Rails.env.development?

    auth_spotify_callback_url(host: "127.0.0.1", port: request.port, protocol: "http")
  end
end
