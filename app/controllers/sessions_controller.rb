# frozen_string_literal: true

# Controller to handle sessions
class SessionsController < ApplicationController
  include SecurableController

  layout 'login'

  skip_forgery_protection only: :create

  def new
    redirect_to root_path if user_signed_in?
  end

  def create
    validate_referer
    result = LoginUserViaAzureIdToken.call(create_params)

    if result.success?
      flash[:notice] = 'Logged in Successfully'
      redirect_to root_path
    else
      flash[:error] = 'Login was unsuccessful. Please try again'
      redirect_to new_session_path
    end
  end

  private

  def create_params
    params.to_unsafe_h.merge({ session: session, stored_state: state_cookie })
  end

  def validate_referer
    return if request.referer == 'https://login.microsoftonline.com/'

    raise RefererNotValidError
  end

  def state_cookie
    @state_cookie ||= cookies.delete(:azure_login_state, domain: request.host)
  end

  class RefererNotValidError < StandardError; end
end
