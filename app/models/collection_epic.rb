# CollectionEpic é um join table entre Collection e Epic.
# Permite organizar Epics dentro de Collections com ordenação via position.
class CollectionEpic < ApplicationRecord
  belongs_to :collection
  belongs_to :epic

  validates :collection_id, :epic_id, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :collection_id, uniqueness: { scope: :epic_id, message: "can only add the same epic once per collection" }
  validate :cannot_add_private_epic_from_another_user

  private

  # Uma Collection pode conter apenas:
  # - Epics próprios do owner (public ou private)
  # - Epics públicos de outros users (picked ou não)
  # NÃO pode conter Epics privados de outro user.
  def cannot_add_private_epic_from_another_user
    if epic&.visibility_private? && epic&.user_id != collection&.user_id
      errors.add(:epic_id, "cannot add private Epic from another user")
    end
  end
end
