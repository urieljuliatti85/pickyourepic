require "application_system_test_case"

class HomeTest < ApplicationSystemTestCase
  test "visiting the landing page shows the product name and the main action" do
    visit root_path

    assert_selector "h1", text: "Pick Up Your Epic!"
    assert_text "PICK YOUR EPIC"
  end
end
