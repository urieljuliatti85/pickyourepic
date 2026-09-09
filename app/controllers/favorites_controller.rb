class FavoritesController < ApplicationController
  before_action :require_authentication
  before_action :set_epic, only: [ :create, :destroy ]

  # GET /favorites
  def index
    # includes porque a lista mostra capa, faixa e autor de cada Epic.
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
  # A busca parte de current_user, entao ninguem remove o Favorite de outro.
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

  # Epic privado de outra pessoa nao existe para quem olha de fora: 404, e nao
  # um erro de validacao, que confirmaria que aquele id existe.
  def set_epic
    @epic = Epic.find(params[:epic_id])

    if @epic.visibility_private? && @epic.user_id != current_user.id
      raise ActiveRecord::RecordNotFound
    end
  end

  # O botao vive no Epic, no Discover e no perfil; voltar para a pagina de
  # origem evita jogar o usuario para fora de onde ele estava.
  def redirect_back_to_epic(**flash_options)
    redirect_back fallback_location: epic_path(@epic), **flash_options
  end
end
