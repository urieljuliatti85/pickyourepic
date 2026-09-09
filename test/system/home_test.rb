require "application_system_test_case"

class HomeTest < ApplicationSystemTestCase
  test "visiting the landing page shows the product name and the main action" do
    visit root_path

    assert_selector "h1", text: "Pick Up Your Epic!"
    assert_text "PICK YOUR EPIC"
  end

  # A home logada era um beco sem saida: dizia "Signed in as" e oferecia
  # apenas sair, sem nenhum caminho para as paginas do produto.
  test "a signed in user can reach search and discover from the home page" do
    user = sign_in_as(create_signed_in_user(username: "uriel"))
    visit root_path

    assert_text "Signed in as"

    click_link "Search a track"
    assert_current_path tracks_path

    visit root_path
    click_link "Discover Epics"
    assert_current_path discover_path
  end

  test "the nav is present outside the pages that used to render it" do
    user = sign_in_as(create_signed_in_user(username: "uriel"))
    visit discover_path

    # O nav so era renderizado por tracks/index, entao o resto da app ficava
    # sem navegacao nenhuma.
    click_link "Collections"
    assert_current_path collections_path

    within("nav") { click_link "@#{user.username}" }
    assert_current_path profile_path(user)
  end
end
