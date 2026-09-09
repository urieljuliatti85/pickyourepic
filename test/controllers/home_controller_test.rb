require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "root renders the landing page" do
    get root_url

    assert_response :success
    # A headline tem markup interno (a palavra em destaque e um span),
    # entao a comparacao e por trecho, nao por igualdade exata.
    assert_select "h1", /momento máximo/
  end
end
