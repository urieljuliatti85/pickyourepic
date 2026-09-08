require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 390, 844 ]

  # O OAuth do Spotify nao e percorrivel pelo browser em teste, entao a sessao
  # e estabelecida pela rota que so existe em Rails.env.test?. O POST e feito
  # por um form real para que o cookie ja esteja gravado quando o metodo volta.
  def sign_in_as(user)
    visit root_path
    page.execute_script(<<~JS)
      var f = document.createElement("form");
      f.method = "POST";
      f.action = "/test_session/#{user.id}";
      document.body.appendChild(f);
      f.submit();
    JS
    # A navegacao do submit termina antes desta assercao passar.
    assert_current_path(/./, wait: 5)
    user
  end
end
