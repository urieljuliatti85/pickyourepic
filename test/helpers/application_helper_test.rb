require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "formats milliseconds as mm:ss" do
    assert_equal "0:00", formatted_duration(0)
    assert_equal "0:07", formatted_duration(7_000)
    assert_equal "1:47", formatted_duration(107_000)
    assert_equal "4:32", formatted_duration(272_500)
    assert_equal "10:05", formatted_duration(605_000)
  end

  test "renders a placeholder when the duration is unknown" do
    assert_equal "--:--", formatted_duration(nil)
  end
end
