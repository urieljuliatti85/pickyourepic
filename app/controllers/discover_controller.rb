class DiscoverController < ApplicationController
  # GET /discover
  def index
    @epics = Epic
      .where(visibility: :public)
      .left_joins(:picks)
      .includes(:track, :user)
      .group("epics.id")
      .order("COUNT(picks.id) DESC, epics.created_at DESC")
  end
end
