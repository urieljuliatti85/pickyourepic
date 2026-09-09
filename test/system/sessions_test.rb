require "application_system_test_case"

class SessionsTest < ApplicationSystemTestCase
  # O botao de sign in e o unico ponto da app que redireciona para fora do
  # dominio. O Turbo intercepta submits de form e segue o redirect por fetch,
  # o que o Spotify recusa por CORS — o clique falha em silencio. Um teste de
  # integracao nao pega isso: o Turbo so existe no browser.
  test "signing in navigates the browser away from the app" do
    setup_spotify_credentials

    # O destino precisa ser cross-origin: e exatamente isso que o Turbo nao
    # consegue seguir por fetch. Um destino local passaria mesmo com o bug
    # presente. Este host nao existe (.invalid e reservado para isso, RFC 2606),
    # entao nenhuma requisicao sai de fato — o browser navega para a propria
    # pagina de erro de DNS, que ja prova que ele saiu da app por conta propria.
    stub_method(Spotify::Client, :authorize_url, "https://spotify-oauth.invalid/authorize") do
      visit root_path
      within("main") { click_button "Sign in with Spotify" }

      assert_no_current_path(root_path, wait: 5)
    end
  end

  # A rota de sign out sempre funcionou e os testes de controller sempre a
  # chamaram direto, entao ninguem percebeu quando a tela deixou de ter o botao.
  # Este teste passa pela interface: clica no que o usuario ve.
  test "a signed in user can sign out from the nav" do
    user = create_signed_in_user(username: "uriel")
    sign_in_as(user)

    visit discover_path
    assert_text "@uriel"

    click_button "Sign out"

    assert_text "Signed out."
    assert_no_text "@uriel"
  end

  test "signing in without credentials configured reports it instead of doing nothing" do
    clear_spotify_credentials

    visit root_path
    within("main") { click_button "Sign in with Spotify" }

    assert_text "Spotify integration is not configured."
  end

  private

  def setup_spotify_credentials
    @original_spotify_env = SpotifyStubs::SPOTIFY_CREDENTIALS.keys.index_with { |key| ENV[key] }
    SpotifyStubs::SPOTIFY_CREDENTIALS.each { |key, value| ENV[key] = value }
  end

  def clear_spotify_credentials
    @original_spotify_env = SpotifyStubs::SPOTIFY_CREDENTIALS.keys.index_with { |key| ENV[key] }
    SpotifyStubs::SPOTIFY_CREDENTIALS.each_key { |key| ENV[key] = nil }
  end

  def teardown
    @original_spotify_env&.each { |key, value| ENV[key] = value }
    super
  end
end
