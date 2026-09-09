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
    # An instance variable, not a local: the turbo_stream template reads
    # @favorite to tell a rejected save from a successful one.
    @favorite = current_user.favorites.build(epic: @epic)

    if @favorite.save
      respond_to_favorite notice: "Epic favorited!"
    else
      respond_to_favorite alert: helpers.friendly_error(@favorite.errors.first.message)
    end
  end

  # DELETE /epics/:epic_id/favorite
  # The lookup starts from current_user, so nobody removes someone else's Favorite.
  def destroy
    favorite = current_user.favorites.find_by(epic: @epic)

    if favorite
      favorite.destroy
      respond_to_favorite notice: "Removed from favorites."
    else
      respond_to_favorite alert: "This Epic is not in your favorites."
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

  # Turbo Stream responses swap only the favorite button without a full page
  # reload. The HTML fallback redirects back for requests without Turbo support.
  #
  # UX: Toast notification is appended in the turbo_stream template.
  def respond_to_favorite(**flash_options)
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = flash_options[:notice] if flash_options[:notice]
        flash.now[:alert] = flash_options[:alert] if flash_options[:alert]
      end
      format.html { redirect_back fallback_location: epic_path(@epic), **flash_options }
    end
  end
end
