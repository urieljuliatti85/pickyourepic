# CollectionEpic is the join table between Collection and Epic.
# It keeps Epics ordered inside a Collection through position.
class CollectionEpic < ApplicationRecord
  belongs_to :collection
  belongs_to :epic

  validates :collection_id, :epic_id, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :collection_id, uniqueness: { scope: :epic_id, message: "can only add the same epic once per collection" }
  validate :cannot_add_private_epic_from_another_user

  private

  # A Collection may hold only:
  # - the owner's own Epics (public or private)
  # - public Epics from other users (picked or not)
  # It must NOT hold another user's private Epic.
  def cannot_add_private_epic_from_another_user
    if epic&.visibility_private? && epic&.user_id != collection&.user_id
      errors.add(:epic_id, "cannot add private Epic from another user")
    end
  end
end
