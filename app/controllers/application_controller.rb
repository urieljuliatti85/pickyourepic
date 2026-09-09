class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :redirect_localhost_to_loopback_ip

  private

  # Spotify refuses `localhost` as a redirect_uri and takes only 127.0.0.1, so
  # the callback always comes back to the IP. To a browser those are two
  # different sites: a session started on localhost does not carry its cookie
  # to 127.0.0.1, the `state` is missing when the callback checks it, and
  # sign-in fails with a message that invites you to try again — which fails
  # the same way.
  #
  # Moving the visitor across before anything is stored means the mismatch
  # cannot arise. Development only: in production the host is whatever the
  # deployment answers to.
  def redirect_localhost_to_loopback_ip
    return unless Rails.env.development?
    return unless request.host == "localhost"
    return unless request.get? || request.head?

    # The URL is rebuilt from the request rather than from url_for, which drops
    # the query string — a search on localhost would arrive with its term gone.
    #
    # A temporary redirect on purpose: browsers cache a 301 indefinitely, and
    # it would go on redirecting long after this code was removed.
    moved = URI.parse(request.original_url)
    moved.host = "127.0.0.1"

    redirect_to moved.to_s, allow_other_host: true
  end
end
