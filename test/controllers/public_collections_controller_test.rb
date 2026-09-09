require "test_helper"

class PublicCollectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create_user(username: "curator")
    @visitor = create_signed_in_user(username: "visitor")
  end

  def epic_for(user, title:, visibility: :public)
    Epic.create!(user: user, track: create_track, title: title,
                 start_time: 0, end_time: 30_000, visibility: visibility)
  end

  def collection_with(user, title:, epics:, visibility: :public)
    collection = Collection.create!(user: user, title: title, visibility: visibility)
    epics.each_with_index do |epic, position|
      CollectionEpic.create!(collection: collection, epic: epic, position: position)
    end
    collection
  end

  test "GET /collections/discover is public" do
    collection_with(@owner, title: "Openings", epics: [ epic_for(@owner, title: "E1") ])

    get public_collections_path

    assert_response :success
    assert_select "h1", /Public/
    assert_match "Openings", response.body
  end

  test "a private Collection never appears" do
    collection_with(@owner, title: "Secret set", visibility: :private,
                    epics: [ epic_for(@owner, title: "E2") ])

    get public_collections_path

    assert_response :success
    assert_no_match "Secret set", response.body
  end

  # An empty Collection would be a card that opens onto nothing.
  test "a Collection with no Epics is left out" do
    Collection.create!(user: @owner, title: "Nothing here", visibility: :public)

    get public_collections_path

    assert_response :success
    assert_no_match "Nothing here", response.body
  end

  # The leak this screen would otherwise open: CollectionEpic only refuses
  # ANOTHER user's private Epic, so an owner can put their own private Epic in a
  # public Collection.
  test "an owner's private Epic inside a public Collection stays hidden" do
    public_epic = epic_for(@owner, title: "Shown one")
    private_epic = epic_for(@owner, title: "Hidden one", visibility: :private)
    collection_with(@owner, title: "Mixed", epics: [ public_epic, private_epic ])

    get public_collections_path

    assert_response :success
    assert_match "Shown one", response.body
    assert_no_match "Hidden one", response.body
  end

  test "the owner still sees their own private Epic on the Collection page" do
    public_epic = epic_for(@owner, title: "Shown one")
    private_epic = epic_for(@owner, title: "Hidden one", visibility: :private)
    collection = collection_with(@owner, title: "Mixed", epics: [ public_epic, private_epic ])

    sign_in_as(@owner)
    get collection_path(collection)

    assert_response :success
    assert_match "Hidden one", response.body
  end

  test "a visitor does not see the owner's private Epic on the Collection page" do
    public_epic = epic_for(@owner, title: "Shown one")
    private_epic = epic_for(@owner, title: "Hidden one", visibility: :private)
    collection = collection_with(@owner, title: "Mixed", epics: [ public_epic, private_epic ])

    sign_in_as(@visitor)
    get collection_path(collection)

    assert_response :success
    assert_match "Shown one", response.body
    assert_no_match "Hidden one", response.body
  end

  # The point of the screen: someone else's Epics arrive here pickable.
  test "the featured Collection's Epics offer a Pick to a signed in visitor" do
    collection_with(@owner, title: "Openings", epics: [ epic_for(@owner, title: "E3") ])

    sign_in_as(@visitor)
    get public_collections_path

    assert_response :success
    assert_select "button[type=submit]", text: "Pick"
  end

  test "the biggest Collection is featured first" do
    collection_with(@owner, title: "Just one", epics: [ epic_for(@owner, title: "A") ])
    collection_with(@owner, title: "The bigger one",
                    epics: [ epic_for(@owner, title: "B"), epic_for(@owner, title: "C") ])

    get public_collections_path

    assert_response :success
    assert_select "h2", /The bigger one/
  end

  test "the listing loads without an N+1" do
    4.times do |i|
      collection_with(@owner, title: "C#{i}",
                      epics: [ epic_for(@owner, title: "E#{i}a"), epic_for(@owner, title: "E#{i}b") ])
    end

    queries = 0
    counter = ->(*args) { queries += 1 unless args.last[:name].to_s =~ /SCHEMA|TRANSACTION/ }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { get public_collections_path }

    assert_response :success
    assert queries < 20, "expected few queries, got #{queries}"
  end
end
