require "application_system_test_case"

class PublicCollectionsTest < ApplicationSystemTestCase
  # The point of the screen: someone else's Collection is where you find an Epic
  # worth picking, and the Pick happens without leaving the page.
  test "a visitor picks an Epic from someone else's public Collection" do
    visitor = create_signed_in_user(username: "visitor")
    curator = User.create!(username: "curator")
    track = Track.create!(spotify_id: "pc_1", name: "Song", artist_name: "Artist",
                          duration_ms: 240_000)
    epic = Epic.create!(user: curator, track: track, title: "The opening riff",
                        start_time: 0, end_time: 30_000, visibility: :public)
    collection = Collection.create!(user: curator, title: "Openings", visibility: :public)
    CollectionEpic.create!(collection: collection, epic: epic, position: 0)

    sign_in_as(visitor)
    visit public_collections_path

    assert_text "Openings"
    assert_text "The opening riff"

    click_button "Pick"

    assert_button "Picked ✓"
    assert_equal 1, epic.picks.count
  end

  test "a signed out visitor can browse but is not offered a Pick" do
    curator = User.create!(username: "curator2")
    track = Track.create!(spotify_id: "pc_2", name: "Song", artist_name: "Artist",
                          duration_ms: 240_000)
    epic = Epic.create!(user: curator, track: track, title: "Public moment",
                        start_time: 0, end_time: 30_000, visibility: :public)
    collection = Collection.create!(user: curator, title: "Browsable", visibility: :public)
    CollectionEpic.create!(collection: collection, epic: epic, position: 0)

    visit public_collections_path

    assert_text "Browsable"
    assert_text "Public moment"
    assert_no_button "Pick"
  end
end
