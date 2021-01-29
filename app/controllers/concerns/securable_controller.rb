# frozen_string_literal: true

# Public: Add this module to a controller class to add methods to the controller that allow it to
# be accessible only to authenticated users.
module SecurableController
  extend ActiveSupport::Concern

  included do
    helper_method :user_signed_in?, :current_user
    rescue_from UserNotAutherticatedError, with: :handle_unathenticated_user
  end

  # Internal: Call this method in a before_action to ensure the actions are accessible
  # only by authenticated users. If the user is not authenticated it will raise
  # UserNotAutherticatedError. By default this error is caught and handled with the method
  # handle_unathenticated_user which simply redirects the user to the login page. You can override
  # that method in your controller if you want something differnet to be done.
  #
  # Returns nothing.
  def authenticate_user!
    raise UserNotAutherticatedError unless user_signed_in?

    expires_at = session[:expires_at] || 0

    return if expires_at > Time.zone.now.to_i

    session.clear
    raise UserNotAutherticatedError
  end

  def user_signed_in?
    !current_user.nil?
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id].present?
  end

  private

  class UserNotAutherticatedError < StandardError; end

  def handle_unathenticated_user
    flash[:alert] = 'Please sign in before continuing.'
    redirect_to(new_session_path)
  end
end
