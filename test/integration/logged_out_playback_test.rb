require "test_helper"

class LoggedOutPlaybackTest < ActionDispatch::IntegrationTest
  setup do
    owner = User.create!(username: "owner")
    track = Track.create!(spotify_id: "lo1", name: "Skin", artist_name: "Flume", duration_ms: 240_000)
    @epic = Epic.create!(user: owner, track: track, title: "Drop",
                         start_time: 0, end_time: 5_000, visibility: :public)
  end

  # A reproducao usa a conta Spotify do proprio ouvinte (Web Playback SDK),
  # entao deslogado nao ha o que tocar. O que da para consertar e o beco sem
  # saida: antes a pagina culpava o Premium de quem nem tinha entrado.
  test "a signed out visitor is offered sign in, not a premium warning" do
    get epic_path(@epic)

    assert_response :success
    assert_select "form[action=?]", auth_spotify_path
    assert_select "button", /Entrar para ouvir/
    assert_select "p", { text: /Premium é necessário para tocar/, count: 0 }
  end

  test "a signed in non-premium user still sees the premium explanation" do
    # sign_in_as percorre o OAuth real e o profile stubado regrava `product`,
    # entao a conta vira free so depois do login.
    user = sign_in_as(User.create!(username: "free"))
    user.spotify_account.update!(product: "free")

    get epic_path(@epic)

    assert_response :success
    assert_select "p", /Premium é necessário para tocar/
    assert_select "button", { text: /Entrar para ouvir/, count: 0 }
  end

  test "the playback token is never issued to a signed out visitor" do
    get "/api/playback_token"

    assert_response :redirect
  end
end
