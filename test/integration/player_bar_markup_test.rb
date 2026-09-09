require "test_helper"

class PlayerBarMarkupTest < ActionDispatch::IntegrationTest
  test "player bar keeps controller and turbo-permanent on the same element" do
    user = sign_in_as
    track = Track.create!(spotify_id: "pb1", name: "S", artist_name: "A", duration_ms: 240_000)
    epic = Epic.create!(user: user, track: track, title: "E", start_time: 0, end_time: 5_000, visibility: :public)

    get epic_path(epic)
    assert_response :success

    # O no preservado pelo Turbo tem que ser o mesmo que hospeda o Stimulus,
    # senao a navegacao recria o controller e derruba o device do SDK.
    assert_select "#player_bar_shell[data-turbo-permanent][data-controller='player-bar']"
  end
end
