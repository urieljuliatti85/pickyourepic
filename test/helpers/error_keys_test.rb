require "test_helper"

# The helper and the models drifted apart once already: seven keys were written
# into FRIENDLY_ERRORS and never used, while the models went on adding raw
# sentences that no screen translated. Nothing failed, because nothing checked
# that the two sides agreed.
class ErrorKeysTest < ActiveSupport::TestCase
  # Every key a model reports has to have an entry, or the user reads
  # "end_time_before_start" off the screen.
  MODEL_KEYS = %w[
    cannot_pick_private_epic
    cannot_pick_own_epic
    cannot_favorite_private_epic_from_another_user
    cannot_add_private_epic_from_another_user
    invalid_mmss_format
    end_time_before_start
    end_time_exceeds_duration
    pick_already_exists
    favorite_already_exists
    collection_epic_already_exists
  ].freeze

  test "every key the models report has a friendly message" do
    missing = MODEL_KEYS.reject { |key| ErrorMessagesHelper::FRIENDLY_ERRORS.key?(key.to_sym) }

    assert_empty missing, "these keys are reported but have no entry: #{missing.join(", ")}"
  end

  test "every friendly message has both a title and an explanation" do
    incomplete = ErrorMessagesHelper::FRIENDLY_ERRORS.reject do |_key, data|
      data[:title].present? && data[:message].present?
    end

    assert_empty incomplete.keys, "these entries are missing a title or a message: #{incomplete.keys.join(", ")}"
  end

  # The keys are read off `errors.add`, so a rename in a model that forgets the
  # helper shows up here rather than on the screen.
  test "the keys listed here are the ones the models actually add" do
    sources = Dir[Rails.root.join("app/models/*.rb")].map { |path| File.read(path) }.join

    unused = MODEL_KEYS.reject { |key| sources.include?(%("#{key}")) }

    assert_empty unused, "these keys are listed here but no model adds them: #{unused.join(", ")}"
  end
end
