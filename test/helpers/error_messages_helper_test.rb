# frozen_string_literal: true

require "test_helper"

class ErrorMessagesHelperTest < ActionView::TestCase
  test "friendly_error returns friendly title for known error" do
    result = friendly_error(:cannot_pick_private_epic)
    assert_equal "🔒 Can't pick private Epics", result
  end

  test "friendly_error_message returns detailed message" do
    result = friendly_error_message(:cannot_pick_private_epic)
    assert result.include?("Only public Epics")
  end

  test "friendly_error handles unknown error gracefully" do
    result = friendly_error(:unknown_error)
    assert_equal "unknown_error", result
  end

  test "error_icon extracts emoji from friendly error" do
    result = error_icon(:cannot_pick_own_epic)
    assert_equal "🎯", result
  end

  test "all error keys have friendly messages" do
    ErrorMessagesHelper::FRIENDLY_ERRORS.each_key do |error_key|
      friendly = friendly_error(error_key)
      message = friendly_error_message(error_key)

      assert friendly.present?, "Missing friendly error for #{error_key}"
      assert message.present?, "Missing friendly message for #{error_key}"
      assert friendly.match?(/^[^a-z]/), "Error title should start with emoji for #{error_key}"
    end
  end
end
