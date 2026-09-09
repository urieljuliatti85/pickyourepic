# Collection groups Epics into curated sets (docs/product.md).
# A Collection can hold the user's own Epics or Epics they picked.
# Epics inside a Collection are ordered by position.
class Collection < ApplicationRecord
  belongs_to :user
  has_many :collection_epics, -> { order(:position) }, dependent: :destroy
  has_many :epics, through: :collection_epics, source: :epic

  enum :visibility, { public: 0, private: 1 }, prefix: :visibility

  validates :title, presence: true, length: { minimum: 1, maximum: 255 }

  # What `viewer` is allowed to see inside this Collection.
  #
  # A public Collection can hold its owner's own private Epics — CollectionEpic
  # only refuses another user's private one — so listing the rows directly would
  # show a visitor something the owner kept private. The owner still sees all of
  # theirs; a signed out viewer passes nil and sees only the public ones.
  def collection_epics_visible_to(viewer)
    rows = collection_epics.includes(epic: [ :track, :user, :picks ])
    return rows if viewer && viewer.id == user_id

    rows.where(epics: { visibility: :public }).references(:epics)
  end

  # Same rule as above, but reading the already-loaded association instead of
  # querying: the listing screens preload `epics` for every Collection, and a
  # scope here would throw that preload away and fire one query per card.
  def epics_visible_to(viewer)
    return epics.to_a if viewer && viewer.id == user_id

    epics.select(&:visibility_public?)
  end
end
