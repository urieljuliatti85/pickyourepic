module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :signed_in?
  end

  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = session[:user_id] && User.find_by(id: session[:user_id])
  end

  def signed_in? = current_user.present?

  def sign_in(user)
    # Evita fixacao de sessao: a sessao antiga e descartada no login.
    reset_session
    session[:user_id] = user.id
    @current_user = user
  end

  def sign_out
    reset_session
    @current_user = nil
  end

  def require_authentication
    return if signed_in?

    redirect_to root_path, alert: "Sign in with Spotify to continue."
  end
end
