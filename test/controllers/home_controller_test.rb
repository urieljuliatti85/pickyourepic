require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "root renders the landing page" do
    get root_url

    assert_response :success
    assert_select "h1", "Pick Up Your Epic!"
  end
end
