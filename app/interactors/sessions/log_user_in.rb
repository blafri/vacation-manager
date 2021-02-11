# frozen_string_literal: true

module Sessions
  # Internal: logs the user in by setting the user_id in the session. The context keys expected
  # are as follows:
  #   session - (required) An ActionDispatch::Request::Session to add the user_id to.
  #   user    - (required) A User object to log in.
  #
  # Examples
  #
  #   Sessions::LogUserIn.call(session: browser_session, user: User.first)
  #   #=> Interactor::Context
  class LogUserIn
    include Interactor

    def call
      session[:user_id] = user.id
      session[:expires_at] = 8.hours.from_now.to_i
    end

    private

    # Internal: Fetch the session object from the context.
    #
    # Returns a ActionDispatch::Request::Session object.
    def session
      context.session
    end

    # Internal: fetch the user from the context.
    #
    # Returns a User object.
    def user
      context.user
    end
  end
end
