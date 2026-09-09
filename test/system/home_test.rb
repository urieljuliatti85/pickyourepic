require "application_system_test_case"

class HomeTest < ApplicationSystemTestCase
  test "visiting the landing page shows the product name and the main action" do
    visit root_path

    assert_selector "h1", text: "peak moment"
    assert_text "Three ideas"
  end

  # The signed-in home was a dead end: it said "Signed in as" and offered only a
  # way out, with no path to the product's pages.
  test "a signed in user can reach search and discover from the home page" do
    user = sign_in_as(create_signed_in_user(username: "uriel"))
    visit root_path

    assert_text "Signed in as"

    click_link "Search for a song"
    assert_current_path tracks_path

    visit root_path
    click_link "Discover Epics"
    assert_current_path discover_path
  end

  test "the nav is present outside the pages that used to render it" do
    user = sign_in_as(create_signed_in_user(username: "uriel"))
    visit discover_path

    # The nav was only rendered by tracks/index, so the rest of the app had no
    # navigation at all.
    # "Collections" is everyone's public ones; "Mine" is the user's own area.
    click_link "Collections"
    assert_current_path public_collections_path

    click_link "Mine"
    assert_current_path collections_path

    within("nav") { click_link "@#{user.username}" }
    assert_current_path profile_path(user)
  end
end
