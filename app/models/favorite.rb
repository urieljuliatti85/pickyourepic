# Favorite representa um user salvando um Epic para si.
#
# Diferente de Pick, que e um ato publico e so vale para Epic publico de outra
# pessoa (docs/product.md § Who Picked an Epic): favoritar e privado, aparece
# so para quem favoritou, e vale tambem para o proprio Epic. A unica coisa que
# nao da para favoritar e Epic privado de outro user — o mesmo limite que rege
# Pick e CollectionEpic (CLAUDE.md § Authorization).
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
