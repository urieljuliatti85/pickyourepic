class PublicCollectionsController < ApplicationController
  # GET /collections/discover
  #
  # Public, like DiscoverController: a Collection is how someone else's Epics
  # arrive in front of you, and a visitor who cannot browse has nothing to sign
  # in for. Signing in is what Picking needs, not looking.
  def index
    # An empty Collection has nothing to open and nothing to pick, so it would
    # only be a dead card in the rail.
    @collections = Collection
      .visibility_public
      .joins(:collection_epics)
      .includes(:user, epics: :track)
      .group("collections.id")
      .order("COUNT(collection_epics.id) DESC, collections.created_at DESC")
  end
end
