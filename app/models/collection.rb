# Collection groups Epics into curated sets (docs/product.md).
# A Collection can hold the user's own Epics or Epics they picked.
# Epics inside a Collection are ordered by position.
class Collection < ApplicationRecord
  belongs_to :user
  has_many :collection_epics, -> { order(:position) }, dependent: :destroy
  has_many :epics, through: :collection_epics, source: :epic

  enum :visibility, { public: 0, private: 1 }, prefix: :visibility

  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
end
