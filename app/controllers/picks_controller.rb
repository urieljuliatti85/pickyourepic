class PicksController < ApplicationController
  before_action :require_authentication
  before_action :set_epic

  # POST /epics/:epic_id/pick
  def create
    @pick = @epic.picks.build(user: current_user)

    if @pick.save
      respond_to_pick notice: "Epic foi pickado!"
    else
      respond_to_pick alert: @pick.errors.full_messages.first
    end
  end

  # DELETE /epics/:epic_id/pick
  # Desfaz o Pick do usuario logado. So o proprio Pick e alcancavel: a busca
  # parte de current_user, entao nao ha como remover o Pick de outra pessoa.
  def destroy
    pick = current_user.picks.find_by(epic: @epic)

    if pick
      pick.destroy
      respond_to_pick notice: "Pick desfeito."
    else
      respond_to_pick alert: "Você ainda não pickou este Epic."
    end
  end

  private

  def set_epic
    @epic = Epic.find(params[:epic_id])
  end

  # Turbo troca so o botao e a contagem; sem isso a pagina inteira recarregava
  # e quem estava no meio de uma lista perdia a posicao. O redirect continua
  # existindo para requisicao sem Turbo (e para os testes que o seguem).
  def respond_to_pick(**flash_options)
    # A associacao foi carregada antes da mudanca; recarrega para a contagem e
    # a lista refletirem o Pick que acabou de entrar ou sair.
    @epic.picks.reset
    @picks = @epic.picks.includes(:user).order(created_at: :desc)

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = flash_options[:notice] if flash_options[:notice]
        flash.now[:alert] = flash_options[:alert] if flash_options[:alert]
      end
      format.html { redirect_back fallback_location: epic_path(@epic), **flash_options }
    end
  end
end
