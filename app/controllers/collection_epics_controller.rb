class CollectionEpicsController < ApplicationController
  before_action :require_authentication
  before_action :set_collection
  before_action :authorize_collection_owner

  # GET /collections/:collection_id/collection_epics/new
  # Busca de Epics para adicionar. Responde tambem em turbo_stream: digitar no
  # campo troca so a lista de resultados, sem recarregar a pagina.
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
      redirect_to @collection, notice: "Epic adicionado à Collection!"
    else
      redirect_to @collection, alert: @collection_epic.errors.full_messages.first
    end
    # A validacao de CollectionEpic e a ultima palavra: mesmo que a busca
    # ofereça algo indevido, o save recusa (CLAUDE.md § Authorization).
  end

  # DELETE /collections/:collection_id/collection_epics/:id
  def destroy
    @collection_epic = @collection.collection_epics.find(params[:id])
    @collection_epic.destroy
    redirect_to @collection, notice: "Epic removido da Collection!"
  end

  private

  def set_collection
    @collection = Collection.find(params[:collection_id])
  end

  def authorize_collection_owner
    unless @collection.user == current_user
      redirect_to collections_path, alert: "Acesso não autorizado."
    end
  end
end
