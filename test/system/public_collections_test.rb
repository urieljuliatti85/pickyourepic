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
  # The scenario as it looks with real accounts: several people, a Collection
  # holding Epics by more than one of them, and the visitor picking from inside
  # it. Exercised in a browser against a copy of the development database before
  # being written down here.
  test "a visitor picks Epics from public Collections built by several people" do
    visitor = create_signed_in_user(username: "uriel")
    mariana = User.create!(username: "mariana_riffs")
    joao = User.create!(username: "joao_drops")

    riff = epic_by(mariana, "The riff that opens it all")
    beat = epic_by(mariana, "That beat right at the start")
    fill = epic_by(joao, "The live drum fill")

    collection = Collection.create!(user: joao, title: "Live moments",
                                    description: "Takes that only happen on stage.",
                                    visibility: :public)
    [ fill, riff, beat ].each_with_index do |epic, position|
      CollectionEpic.create!(collection: collection, epic: epic, position: position)
    end

    sign_in_as(visitor)
    visit public_collections_path

    # Everything in the Collection is offered, whoever made it.
    assert_text "Live moments"
    assert_text "by @joao_drops"
    assert_text "by @mariana_riffs"
    assert_equal 3, all("turbo-frame[id^='pick_button'] button").size

    within("li", text: "The live drum fill") do
      click_button "Pick"
      assert_button "Picked ✓"
    end
    assert_text "Epic picked!"

    # Wait for the button to flip before reading the database: the Pick lands
    # over a turbo_stream, so asserting straight after the click races it.
    within("li", text: "The riff that opens it all") do
      click_button "Pick"
      assert_button "Picked ✓"
    end

    assert_equal 1, fill.picks.count
    assert_equal 1, riff.picks.count
    assert_equal visitor, fill.picks.first.user
  end

  # A Collection is someone's set, but a Pick is still per Epic: picking one
  # leaves the others alone.
  test "picking inside a Collection picks the Epic, not the Collection" do
    visitor = create_signed_in_user(username: "uriel2")
    owner = User.create!(username: "curator3")

    first = epic_by(owner, "First moment")
    second = epic_by(owner, "Second moment")
    collection = Collection.create!(user: owner, title: "Two moments", visibility: :public)
    [ first, second ].each_with_index do |epic, position|
      CollectionEpic.create!(collection: collection, epic: epic, position: position)
    end

    sign_in_as(visitor)
    visit public_collections_path

    within("li", text: "First moment") do
      click_button "Pick"
      assert_button "Picked ✓"
    end
    assert_text "Epic picked!"

    assert_equal 1, first.picks.count
    assert_equal 0, second.picks.count
    within("li", text: "Second moment") { assert_button "Pick" }
  end

  def epic_by(user, title)
    track = Track.create!(spotify_id: "rc_#{SecureRandom.hex(4)}", name: "Song",
                          artist_name: "Artist", duration_ms: 240_000)
    Epic.create!(user: user, track: track, title: title,
                 start_time: 0, end_time: 30_000, visibility: :public)
  end
end
