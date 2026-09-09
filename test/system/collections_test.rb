require "application_system_test_case"

class CollectionsTest < ApplicationSystemTestCase
  def setup
    @user = create_signed_in_user(username: "uriel")
    sign_in_as(@user)
    @track = Track.create!(
      spotify_id: "track_sys",
      name: "System Test Song",
      artist_name: "Test Artist",
      duration_ms: 300_000
    )
  end

  test "User can create a collection" do
    visit collections_path
    click_link "New Collection"

    fill_in "Title", with: "My Playlist"
    fill_in "Description (optional)", with: "Best moments"
    choose "Public"
    click_button "Create Collection"

    assert_text "Collection created!"
    assert_text "My Playlist"
  end

  test "User can edit a collection" do
    collection = Collection.create!(user: @user, title: "Old Name")

    visit edit_collection_path(collection)
    fill_in "Title", with: "New Name"
    click_button "Update Collection"

    assert_text "Collection updated!"
    assert_text "New Name"
  end

  test "User can delete a collection" do
    Collection.create!(user: @user, title: "Delete Me")

    visit collections_path
    assert_text "Delete Me"

    click_link "Delete Me"
    # The button uses data-turbo-confirm, which opens a native browser dialog.
    accept_confirm { click_button "Delete" }

    assert_text "Collection deleted!"
  end

  test "User can add and remove epic from collection" do
    collection = Collection.create!(user: @user, title: "My Collection")
    epic = Epic.create!(
      user: @user,
      track: create_track,
      title: "Epic Song",
      start_time: 0,
      end_time: 100_000,
      visibility: :public
    )

    visit collection_path(collection)
    click_link "Search for an Epic"
    fill_in "q", with: "Epic Song"
    click_button "Add"

    assert_text "Epic added to the Collection!"
    assert_text "Epic Song"

    click_button "Remove"
    assert_text "Epic removed from the Collection!"
  end

  test "User adds an epic to a collection by searching for it" do
    other = User.create!(username: "bandmate")
    track = Track.create!(spotify_id: "srch1", name: "Bohemian Rhapsody",
                          artist_name: "Queen", duration_ms: 300_000)
    Epic.create!(user: other, track: track, title: "O solo",
                 start_time: 0, end_time: 30_000, visibility: :public)

    collection = Collection.create!(user: @user, title: "Busca", visibility: :public)

    visit collection_path(collection)
    click_link "Search for an Epic"

    # Search by band: the Epic has no "queen" in its title.
    fill_in "q", with: "queen"

    assert_text "O solo"
    assert_text "Bohemian Rhapsody"

    click_button "Add"

    assert_text "Epic added to the Collection!"
    assert_text "O solo"
  end
end
