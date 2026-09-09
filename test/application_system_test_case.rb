require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 390, 844 ]

  # Spotify's OAuth cannot be walked by the browser under test, so the session is
  # established through the route that only exists in Rails.env.test?. The POST
  # goes through a real form so the cookie is already written when this returns.
  def sign_in_as(user)
    visit root_path
    page.execute_script(<<~JS)
      var f = document.createElement("form");
      f.method = "POST";
      f.action = "/test_session/#{user.id}";
      document.body.appendChild(f);
      f.submit();
    JS
    # The submit's navigation finishes before this assertion passes.
    assert_current_path(/./, wait: 5)
    user
  end
end
