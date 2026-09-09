require "test_helper"

class ProfileLayoutTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(username: "flume", bio: "Faço Epics.")
  end

  def epic_for(user, n, visibility: :public)
    track = Track.create!(spotify_id: "pf#{n}#{user.id}", name: "T#{n}", artist_name: "A#{n}",
                          album_artwork_url: "https://i.scdn.co/image/p#{n}", duration_ms: 200_000)
    Epic.create!(user: user, track: track, title: "E#{n}", start_time: 0,
                 end_time: 30_000, visibility: visibility)
  end

  test "the profile lists epics as numbered rows with artwork" do
    3.times { |i| epic_for(@owner, i) }

    get profile_path(@owner)

    assert_response :success
    assert_select "ol li", 3
    assert_select "li", /01/
    assert_select "img[src=?]", "https://i.scdn.co/image/p0"
  end

  test "a private epic never appears on the profile" do
    epic_for(@owner, 9, visibility: :private)

    get profile_path(@owner)

    assert_response :success
    assert_select "li", { text: /E9/, count: 0 }
  end

  test "picked epics show whose they are" do
    other = User.create!(username: "someone")
    epic = epic_for(other, 5)
    Pick.create!(user: @owner, epic: epic)

    get profile_path(@owner)

    assert_response :success
    assert_select "li", /by @someone/
  end

  test "the private profile page renders without the epic lists" do
    private_user = User.create!(username: "hidden", visibility: :private_profile)
    epic_for(private_user, 7)

    get profile_path(private_user)

    assert_response :success
    assert_match "This profile is private", response.body
    assert_select "ol li", false
  end

  # The Pick button now appears in the profile's rows, so the model's rules
  # (CLAUDE.md § Authorization) have to hold here too.
  test "the profile rows offer Pick for another user's epic" do
    visitor = create_signed_in_user(username: "visitor")
    epic_for(@owner, 3)
    sign_in_as(visitor)

    get profile_path(@owner)

    assert_response :success
    assert_select "button[type=submit]", text: "Pick"
  end

  test "the profile rows do not offer Pick on your own epic" do
    epic_for(@owner, 4)
    sign_in_as(@owner)

    get profile_path(@owner)

    assert_response :success
    assert_select "button[type=submit]", { text: "Pick", count: 0 }
  end

  test "an already picked epic shows the undo state on the profile" do
    visitor = create_signed_in_user(username: "visitor2")
    epic = epic_for(@owner, 6)
    Pick.create!(user: visitor, epic: epic)
    sign_in_as(visitor)

    get profile_path(@owner)

    assert_response :success
    assert_select "button[type=submit]", text: "Picked ✓"
  end

  # The button calls picked_epic_ids instead of an exists? per row; without it
  # every Epic on the page would add a query.
  test "the profile loads its lists without an N+1 while signed in" do
    visitor = create_signed_in_user(username: "visitor3")
    5.times { |i| Pick.create!(user: visitor, epic: epic_for(@owner, i)) }
    sign_in_as(visitor)

    queries = 0
    counter = ->(*args) { queries += 1 unless args.last[:name].to_s =~ /SCHEMA|TRANSACTION/ }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { get profile_path(@owner) }

    assert_response :success
    assert queries < 20, "esperado poucas queries, foram #{queries}"
  end

  test "the profile loads its lists without an N+1" do
    5.times { |i| epic_for(@owner, i) }

    queries = 0
    counter = ->(*args) { queries += 1 unless args.last[:name].to_s =~ /SCHEMA|TRANSACTION/ }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { get profile_path(@owner) }

    assert_response :success
    assert queries < 15, "esperado poucas queries, foram #{queries}"
  end
end
