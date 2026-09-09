require "test_helper"

class PlayerBarTransportTest < ActionDispatch::IntegrationTest
  setup do
    @user = sign_in_as
    @track = Track.create!(spotify_id: "pb9", name: "Skin", artist_name: "Flume",
                           album_artwork_url: "https://i.scdn.co/image/a", duration_ms: 240_000)
    @epic = Epic.create!(user: @user, track: @track, title: "Drop",
                         start_time: 0, end_time: 5_000, visibility: :public)
  end

  test "the bar renders the full transport" do
    get epic_path(@epic)

    assert_response :success
    assert_select "#player_bar_shell[data-turbo-permanent][data-controller='player-bar']"
    assert_select "[data-player-bar-target='prev']"
    assert_select "[data-player-bar-target='next']"
    assert_select "[data-player-bar-target='button']"
    assert_select "[data-player-bar-target='artwork']"
    assert_select "[data-player-bar-target='scrubber'][type='range']"
    assert_select "[data-player-bar-target='volume'][type='range']"
    assert_select "[data-player-bar-target='elapsed']"
    assert_select "[data-player-bar-target='total']"
  end

  test "a collection dispatches its whole queue to the bar" do
    collection = Collection.create!(user: @user, title: "Set", visibility: :public)
    CollectionEpic.create!(collection: collection, epic: @epic, position: 0)

    get collection_path(collection)

    assert_response :success
    # A Collection nao instancia SDK proprio: so despacha a fila.
    assert_select "[data-action='play-request#playQueue']"
    queue = JSON.parse(css_select("[data-play-request-queue-value]").first["data-play-request-queue-value"])
    assert_equal 1, queue.size
    assert_equal "spotify:track:pb9", queue.first["uri"]
    assert_equal 5_000, queue.first["endTime"]
    assert_equal "https://i.scdn.co/image/a", queue.first["artwork"]
  end

  test "an empty collection offers no dead play button" do
    empty = Collection.create!(user: @user, title: "Vazia", visibility: :public)

    get collection_path(empty)

    assert_response :success
    assert_select "[data-action='play-request#playQueue']", false
  end
end
