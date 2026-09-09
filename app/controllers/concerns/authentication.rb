module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :signed_in?, :sidebar_epics, :sidebar_collections
  end

  private

  # A sidebar aparece em toda pagina, entao estas duas consultas rodariam a
  # cada request. Memoizadas: so acontecem se a sidebar de fato renderizar
  # (visitante deslogado nao dispara nenhuma), e uma unica vez por request.
  SIDEBAR_LIMIT = 8

  def sidebar_epics
    return [] unless signed_in?

    @sidebar_epics ||= current_user.epics
                                   .includes(:track)
                                   .order(created_at: :desc)
                                   .limit(SIDEBAR_LIMIT)
  end

  def sidebar_collections
    return [] unless signed_in?

    @sidebar_collections ||= current_user.collections
                                         .order(created_at: :desc)
                                         .limit(SIDEBAR_LIMIT)
  end

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
