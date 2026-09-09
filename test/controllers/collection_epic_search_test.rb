require "test_helper"

class CollectionEpicSearchTest < ActionDispatch::IntegrationTest
  setup do
    @user = sign_in_as
    @other = User.create!(username: "other")
    @collection = Collection.create!(user: @user, title: "Set", visibility: :public)
  end

  def epic_for(user, title:, track_name: "Song", artist: "Band", visibility: :public)
    track = Track.create!(spotify_id: "s#{SecureRandom.hex(4)}", name: track_name,
                          artist_name: artist, duration_ms: 200_000)
    Epic.create!(user: user, track: track, title: title, start_time: 0,
                 end_time: 5_000, visibility: visibility)
  end

  test "searching by epic title" do
    epic_for(@other, title: "The Breakdown")
    epic_for(@other, title: "Something else")

    get new_collection_collection_epic_path(@collection, q: "breakdown")

    assert_response :success
    assert_select "#epic_search_results li", 1
    assert_match "The Breakdown", response.body
  end

  test "searching by track name" do
    epic_for(@other, title: "X", track_name: "Bohemian Rhapsody")

    get new_collection_collection_epic_path(@collection, q: "bohemian")

    assert_response :success
    assert_match "Bohemian Rhapsody", response.body
  end

  test "searching by artist name" do
    epic_for(@other, title: "X", artist: "Imagine Dragons")

    get new_collection_collection_epic_path(@collection, q: "dragons")

    assert_response :success
    assert_match "Imagine Dragons", response.body
  end

  test "search is case insensitive" do
    epic_for(@other, title: "Thunder")

    get new_collection_collection_epic_path(@collection, q: "THUNDER")

    assert_response :success
    assert_match "Thunder", response.body
  end

  # The limit that matters: the search must not offer what the save would refuse.
  test "another user's private epic never appears" do
    epic_for(@other, title: "Segredo", visibility: :private)

    get new_collection_collection_epic_path(@collection, q: "segredo")

    assert_response :success
    assert_select "#epic_search_results li", 0
  end

  test "the user's own private epic does appear" do
    epic_for(@user, title: "Meu segredo", visibility: :private)

    get new_collection_collection_epic_path(@collection, q: "segredo")

    assert_response :success
    assert_select "#epic_search_results li", 1
  end

  test "an epic already in the collection is not offered again" do
    epic = epic_for(@other, title: "Already")
    CollectionEpic.create!(collection: @collection, epic: epic, position: 0)

    get new_collection_collection_epic_path(@collection, q: "already")

    assert_response :success
    assert_select "#epic_search_results li", 0
  end

  test "a wildcard is treated as text, not as a pattern" do
    epic_for(@other, title: "Real title")

    get new_collection_collection_epic_path(@collection, q: "%")

    assert_response :success
    assert_select "#epic_search_results li", 0
  end

  test "only the owner can search into a collection" do
    theirs = Collection.create!(user: @other, title: "Deles", visibility: :public)

    get new_collection_collection_epic_path(theirs, q: "a")

    assert_redirected_to collections_path
  end

  test "adding from the results puts the epic in the collection" do
    epic = epic_for(@other, title: "Add me")

    assert_difference "CollectionEpic.count", 1 do
      post collection_collection_epics_path(@collection, epic_id: epic.id)
    end

    assert_redirected_to collection_path(@collection)
  end

  test "the search answers turbo stream for type-ahead" do
    epic_for(@other, title: "Streamed")

    get new_collection_collection_epic_path(@collection, q: "streamed"), as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match "epic_search_results", response.body
  end
end
