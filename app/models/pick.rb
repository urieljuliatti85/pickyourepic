# Pick representa um usuário escolhendo um Epic público criado por outro usuário (docs/product.md).
# Um user não pode fazer Pick do mesmo Epic duas vezes (CLAUDE.md § 6).
# Pick não duplica o Epic; apenas registra a escolha do user.
class Pick < ApplicationRecord
  belongs_to :user
  belongs_to :epic

  validates :user_id, :epic_id, presence: true
  validates :user_id, uniqueness: { scope: :epic_id, message: "can only pick the same epic once" }
  validate :cannot_pick_private_epic
  validate :cannot_pick_own_epic

  private

  # Pick apenas de Epics públicos (docs/product.md: Privacy)
  def cannot_pick_private_epic
    if epic&.visibility_private?
      errors.add(:epic_id, "cannot pick private epic")
    end
  end

  # Um user não faz Pick de seu próprio Epic
  def cannot_pick_own_epic
    if epic&.user_id == user_id
      errors.add(:epic_id, "cannot pick your own epic")
    end
  end
end
