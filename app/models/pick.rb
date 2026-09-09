# Pick is a user choosing a public Epic created by someone else
# (docs/product.md). A user cannot Pick the same Epic twice
# (CLAUDE.md § Domain rules and where they are enforced).
# A Pick does not duplicate the Epic; it only records the choice.
#
# Error messages are user-friendly and include context (see app/helpers/error_messages_helper.rb).
class Pick < ApplicationRecord
  belongs_to :user
  belongs_to :epic

  validates :user_id, :epic_id, presence: true
  validates :user_id, uniqueness: { scope: :epic_id, message: "pick_already_exists" }
  validate :cannot_pick_private_epic
  validate :cannot_pick_own_epic

  private

  # Pick only public Epics (docs/product.md: Privacy)
  def cannot_pick_private_epic
    if epic&.visibility_private?
      errors.add(:base, "cannot_pick_private_epic")
    end
  end

  # A user does not Pick their own Epic
  def cannot_pick_own_epic
    if epic&.user_id == user_id
      errors.add(:base, "cannot_pick_own_epic")
    end
  end
end
