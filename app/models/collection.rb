# Collection organiza Epics em grupos curados (docs/product.md).
# Uma Collection pode conter Epics próprios ou Epics que o user pickou.
# Epics dentro de uma Collection podem ser ordenados via position.
class Collection < ApplicationRecord
  belongs_to :user
  has_many :collection_epics, -> { order(:position) }, dependent: :destroy
  has_many :epics, through: :collection_epics, source: :epic

  enum :visibility, { public: 0, private: 1 }, prefix: :visibility

  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
end
