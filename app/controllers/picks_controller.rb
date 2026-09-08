class PicksController < ApplicationController
  before_action :require_authentication
  before_action :set_epic

  # POST /epics/:epic_id/pick
  def create
    @pick = @epic.picks.build(user: current_user)

    if @pick.save
      redirect_to @epic, notice: "Epic foi pickado!"
    else
      redirect_to @epic, alert: @pick.errors.full_messages.first
    end
  end

  # DELETE /epics/:epic_id/pick
  # Desfaz o Pick do usuario logado. So o proprio Pick e alcancavel: a busca
  # parte de current_user, entao nao ha como remover o Pick de outra pessoa.
  def destroy
    pick = current_user.picks.find_by(epic: @epic)

    if pick
      pick.destroy
      redirect_to @epic, notice: "Pick desfeito."
    else
      redirect_to @epic, alert: "Você ainda não pickou este Epic."
    end
  end

  private

  def set_epic
    @epic = Epic.find(params[:epic_id])
  end
end
