class CollectionsController < ApplicationController
  before_action :require_authentication
  before_action :set_collection, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_collection_owner, only: [ :edit, :update, :destroy ]

  # GET /collections
  def index
    # `epics: :track` porque o card mostra a capa do primeiro Epic; sem isso
    # a rail dispara duas queries por Collection.
    @collections = current_user.collections
      .includes(epics: :track)
      .order(created_at: :desc)
  end

  # GET /collections/new
  def new
    @collection = Collection.new
  end

  # POST /collections
  def create
    @collection = current_user.collections.build(collection_params)

    if @collection.save
      redirect_to @collection, notice: "Collection created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /collections/:id
  def show
    # Public collections visible to all, private only to owner
    if @collection.visibility_private? && @collection.user != current_user
      redirect_to collections_path, alert: "Collection not found."
    end
  end

  # GET /collections/:id/edit
  def edit
  end

  # PATCH /collections/:id
  def update
    if @collection.update(collection_params)
      redirect_to @collection, notice: "Collection updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /collections/:id
  def destroy
    @collection.destroy
    redirect_to collections_path, notice: "Collection deleted!"
  end

  private

  def set_collection
    @collection = Collection.find(params[:id])
  end

  def authorize_collection_owner
    unless @collection.user == current_user
      redirect_to collections_path, alert: "Not authorized."
    end
  end

  def collection_params
    params.require(:collection).permit(:title, :description, :visibility)
  end
end
