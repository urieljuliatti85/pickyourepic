class PicksController < ApplicationController
  before_action :require_authentication
  before_action :set_epic

  # POST /epics/:epic_id/picks
  def create
    @pick = @epic.picks.build(user: current_user)

    if @pick.save
      redirect_to @epic, notice: "Epic foi pickado!"
    else
      redirect_to @epic, alert: @pick.errors.full_messages.first
    end
  end

  private

  def set_epic
    @epic = Epic.find(params[:epic_id])
  end
end
