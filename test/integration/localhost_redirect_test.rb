require "test_helper"

# Spotify takes 127.0.0.1 as a redirect_uri and refuses `localhost`, so the
# OAuth callback always lands on the IP. A browser treats the two as separate
# sites, so a session begun on localhost loses its cookie on the way back, the
# `state` is gone when the callback checks it, and sign-in fails — telling the
# user to try again, which fails identically.
class LocalhostRedirectTest < ActionDispatch::IntegrationTest
  test "a visit to localhost moves to the loopback IP" do
    with_development_env do
      get "http://localhost:3000/discover"

      assert_redirected_to "http://127.0.0.1:3000/discover"
    end
  end

  test "the path and query survive the move" do
    with_development_env do
      get "http://localhost:3000/tracks?q=bodom"

      assert_redirected_to "http://127.0.0.1:3000/tracks?q=bodom"
    end
  end

  test "the loopback IP is served, not redirected again" do
    with_development_env do
      get "http://127.0.0.1:3000/discover"

      assert_response :success
    end
  end

  # A 301 would be cached by the browser indefinitely and would go on
  # redirecting long after this code was removed.
  test "the redirect is temporary" do
    with_development_env do
      get "http://localhost:3000/discover"

      assert_equal 302, response.status
    end
  end

  # In production the host is whatever the deployment answers to, and a
  # hardcoded 127.0.0.1 would send every visitor to their own machine.
  test "no redirect outside development" do
    get "http://localhost:3000/discover"

    assert_response :success
  end

  private

  def with_development_env
    stub_method(Rails, :env, ActiveSupport::StringInquirer.new("development")) do
      yield
    end
  end
end
