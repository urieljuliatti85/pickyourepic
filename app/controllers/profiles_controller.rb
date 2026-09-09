class ProfilesController < ApplicationController
  before_action :set_profile_user

  # GET /profiles/:username
  def show
    # If profile is private and user is not the owner, show limited info
    if @user.visibility_private_profile? && (@user != current_user)
      @is_private_profile = true
      return
    end

    # The list shows artwork, track and Pick count for each Epic; without the
    # includes every rendered row fires its own queries.
    @epics = @user.epics.visibility_public.includes(:track, :picks).order(created_at: :desc)
    @picked_epics = Epic.visibility_public
      .joins(:picks).where(picks: { user_id: @user.id })
      .includes(:track, :user, :picks)
      .order("picks.created_at DESC")
    @collections = @user.collections.visibility_public.includes(epics: :track).order(created_at: :desc)
  end

  private

  def set_profile_user
    @user = User.find_by(username: params[:username])
    raise ActiveRecord::RecordNotFound unless @user
  end
end
