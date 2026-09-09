# Sign-in shortcut for system tests. The route is only drawn in Rails.env.test?
# (config/routes.rb), so this class is unreachable in production.
class TestSessionsController < ApplicationController
  skip_forgery_protection

  def create
    raise ActionController::RoutingError, "Not Found" unless Rails.env.test?

    sign_in(User.find(params[:user_id]))
    head :ok
  end
end
