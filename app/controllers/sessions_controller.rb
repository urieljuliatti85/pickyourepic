class SessionsController < ApplicationController
  # O callback chega do Spotify, um contexto externo: nao ha CSRF token nele.
  # A protecao equivalente e o parametro `state`, validado abaixo.
  skip_forgery_protection only: :callback

  # POST /auth/spotify — inicia o fluxo. E POST (e nao GET) para que um link
  # de terceiro nao consiga disparar login.
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

    # State ausente ou divergente => a requisicao nao veio do nosso fluxo.
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

  # O Spotify valida o redirect_uri por igualdade exata contra o que esta
  # cadastrado no dashboard, e rejeita `localhost` (so aceita 127.0.0.1).
  # Derivar do host da requisicao quebra o login de quem abre o app por
  # localhost, entao em development fixamos o host cadastrado.
  def callback_url
    return auth_spotify_callback_url unless Rails.env.development?

    auth_spotify_callback_url(host: "127.0.0.1", port: request.port, protocol: "http")
  end
end
