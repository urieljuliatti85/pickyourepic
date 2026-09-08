class EpicsController < ApplicationController
  before_action :require_authentication, except: [ :show ]
  before_action :set_track, only: [ :new, :create ]
  before_action :set_epic, only: [ :show ]
  before_action :authorize_epic_visibility, only: [ :show ]

  # GET /epics/new?track_id=:id
  def new
    @epic = @track.epics.build(user: current_user)
  end

  # POST /epics
  def create
    @epic = @track.epics.build(epic_params)
    @epic.user = current_user

    if @epic.save
      redirect_to @epic, notice: "Epic was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /epics/:id
  def show
    # @epic já setado por before_action
  end

  private

  def set_track
    @track = Track.find_by!(spotify_id: params[:track_id])
  end

  def set_epic
    @epic = Epic.find(params[:id])
  end

  # Public epics: visíveis para todos
  # Private epics: visíveis apenas para o owner
  def authorize_epic_visibility
    if @epic.visibility_private? && current_user != @epic.user
      redirect_to root_path, alert: "Epic não encontrado."
    end
  end

  def epic_params
    params.require(:epic).permit(:title, :description, :start_time, :end_time, :visibility)
  end
end
