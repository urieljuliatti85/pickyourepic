class CollectionsController < ApplicationController
  before_action :require_authentication
  before_action :set_collection, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_collection_owner, only: [ :edit, :update, :destroy ]

  # GET /collections
  def index
    @collections = current_user.collections.order(created_at: :desc)
  end

  # GET /collections/new
  def new
    @collection = Collection.new
  end

  # POST /collections
  def create
    @collection = current_user.collections.build(collection_params)

    if @collection.save
      redirect_to @collection, notice: "Collection criada!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /collections/:id
  def show
    # Public collections visible to all, private only to owner
    if @collection.visibility_private? && @collection.user != current_user
      redirect_to collections_path, alert: "Collection não encontrada."
    end
  end

  # GET /collections/:id/edit
  def edit
  end

  # PATCH /collections/:id
  def update
    if @collection.update(collection_params)
      redirect_to @collection, notice: "Collection atualizada!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /collections/:id
  def destroy
    @collection.destroy
    redirect_to collections_path, notice: "Collection removida!"
  end

  private

  def set_collection
    @collection = Collection.find(params[:id])
  end

  def authorize_collection_owner
    unless @collection.user == current_user
      redirect_to collections_path, alert: "Acesso não autorizado."
    end
  end

  def collection_params
    params.require(:collection).permit(:title, :description, :visibility)
  end
end
