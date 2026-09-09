class FavoritesController < ApplicationController
  before_action :require_authentication
  before_action :set_epic, only: [ :create, :destroy ]

  # GET /favorites
  def index
    # includes because the list shows artwork, track and author for each Epic.
    @epics = current_user.favorited_epics
      .includes(:track, :user, :picks)
      .order("favorites.created_at DESC")
  end

  # POST /epics/:epic_id/favorite
  def create
    favorite = current_user.favorites.build(epic: @epic)

    if favorite.save
      redirect_back_to_epic notice: "Epic favorited!"
    else
      redirect_back_to_epic alert: favorite.errors.full_messages.first
    end
  end

  # DELETE /epics/:epic_id/favorite
  # The lookup starts from current_user, so nobody removes someone else's Favorite.
  def destroy
    favorite = current_user.favorites.find_by(epic: @epic)

    if favorite
      favorite.destroy
      redirect_back_to_epic notice: "Removed from favorites."
    else
      redirect_back_to_epic alert: "This Epic is not in your favorites."
    end
  end

  private

  # Another user's private Epic does not exist from the outside: 404, not a
  # validation error, which would confirm that the id exists.
  def set_epic
    @epic = Epic.find(params[:epic_id])

    if @epic.visibility_private? && @epic.user_id != current_user.id
      raise ActiveRecord::RecordNotFound
    end
  end

  # The button lives on the Epic page, on Discover and on the profile; going back
  # to where it was clicked avoids throwing the user out of where they were.
  def redirect_back_to_epic(**flash_options)
    redirect_back fallback_location: epic_path(@epic), **flash_options
  end
end
