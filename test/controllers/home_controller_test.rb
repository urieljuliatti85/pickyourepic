require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "root renders the landing page" do
    get root_url

    assert_response :success
    # A headline tem markup interno (a palavra em destaque e um span),
    # so the comparison is by fragment, not exact equality.
    assert_select "h1", /peak moment/
  end
end
