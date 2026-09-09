class CollectionEpicsController < ApplicationController
  before_action :require_authentication
  before_action :set_collection
  before_action :authorize_collection_owner

  # GET /collections/:collection_id/collection_epics/new
  # Search for Epics to add. Also answers in turbo_stream: typing in the field
  # swaps only the result list, without reloading the page.
  def new
    @term = params[:q].to_s

    @results = Epic.addable_by(current_user)
      .matching(@term)
      .where.not(id: @collection.epic_ids)
      .includes(:track, :user)
      .order(created_at: :desc)
      .limit(20)

    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  # POST /collections/:collection_id/collection_epics
  def create
    @collection_epic = @collection.collection_epics.build(
      epic_id: params[:epic_id],
      position: @collection.collection_epics.count
    )

    if @collection_epic.save
      redirect_to @collection, notice: "Epic added to the Collection!"
    else
      redirect_to @collection, alert: @collection_epic.errors.full_messages.first
    end
    # The CollectionEpic validation has the last word: even if the search
    # offered something it should not, the save refuses (CLAUDE.md § Authorization).
  end

  # DELETE /collections/:collection_id/collection_epics/:id
  def destroy
    @collection_epic = @collection.collection_epics.find(params[:id])
    @collection_epic.destroy
    redirect_to @collection, notice: "Epic removed from the Collection!"
  end

  private

  def set_collection
    @collection = Collection.find(params[:collection_id])
  end

  def authorize_collection_owner
    unless @collection.user == current_user
      redirect_to collections_path, alert: "Not authorized."
    end
  end
end
