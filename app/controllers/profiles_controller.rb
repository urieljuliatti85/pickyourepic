class ProfilesController < ApplicationController
  before_action :set_profile_user

  # GET /profiles/:username
  def show
    # If profile is private and user is not the owner, show limited info
    if @user.visibility_private? && (@user != current_user)
      @is_private_profile = true
    end
  end

  private

  def set_profile_user
    @user = User.find_by(username: params[:username])
    raise ActiveRecord::RecordNotFound unless @user
  end
end
