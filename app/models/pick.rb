# Pick is a user choosing a public Epic created by someone else
# (docs/product.md). A user cannot Pick the same Epic twice
# (CLAUDE.md § Domain rules and where they are enforced).
# A Pick does not duplicate the Epic; it only records the choice.
class Pick < ApplicationRecord
  belongs_to :user
  belongs_to :epic

  validates :user_id, :epic_id, presence: true
  validates :user_id, uniqueness: { scope: :epic_id, message: "can only pick the same epic once" }
  validate :cannot_pick_private_epic
  validate :cannot_pick_own_epic

  private

  # Pick only public Epics (docs/product.md: Privacy)
  def cannot_pick_private_epic
    if epic&.visibility_private?
      errors.add(:epic_id, "cannot pick private epic")
    end
  end

  # A user does not Pick their own Epic
  def cannot_pick_own_epic
    if epic&.user_id == user_id
      errors.add(:epic_id, "cannot pick your own epic")
    end
  end
end
