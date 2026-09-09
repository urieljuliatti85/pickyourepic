class PicksController < ApplicationController
  before_action :require_authentication
  before_action :set_epic

  # POST /epics/:epic_id/pick
  def create
    @pick = @epic.picks.build(user: current_user)

    if @pick.save
      respond_to_pick notice: "Epic picked!"
    else
      respond_to_pick alert: @pick.errors.full_messages.first
    end
  end

  # DELETE /epics/:epic_id/pick
  # Undoes the signed-in user's Pick. Only their own is reachable: the lookup
  # starts from current_user, so nobody can remove someone else's Pick.
  def destroy
    pick = current_user.picks.find_by(epic: @epic)

    if pick
      pick.destroy
      respond_to_pick notice: "Pick undone."
    else
      respond_to_pick alert: "You have not picked this Epic yet."
    end
  end

  private

  def set_epic
    @epic = Epic.find(params[:epic_id])
  end

  # Turbo swaps only the button and the count; without it the whole page
  # reloaded and anyone mid-list lost their position. The redirect stays for
  # requests without Turbo (and for the tests that follow it).
  def respond_to_pick(**flash_options)
    # The association was loaded before the change; reload so the count and the
    # list reflect the Pick that just came or went.
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
