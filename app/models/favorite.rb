# Favorite is a user saving an Epic for themselves.
#
# Unlike Pick, which is a public act and only applies to someone else's public
# Epic (docs/product.md § Who Picked an Epic): favoriting is private, shows only
# to whoever favorited, and applies to your own Epic too. The one thing you
# cannot favorite is another user's private Epic — the same limit that governs
# Pick and CollectionEpic (CLAUDE.md § Authorization).
class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :epic

  validates :user_id, uniqueness: { scope: :epic_id, message: "can only favorite the same epic once" }
  validate :cannot_favorite_private_epic_from_another_user

  private

  def cannot_favorite_private_epic_from_another_user
    if epic&.visibility_private? && epic&.user_id != user_id
      errors.add(:epic_id, "cannot favorite private epic from another user")
    end
  end
end
