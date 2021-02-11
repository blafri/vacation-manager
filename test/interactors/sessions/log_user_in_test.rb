# frozen_string_literal: true

require 'test_helper'

module Sessions
  class LogUserInTest < ActiveSupport::TestCase
    test 'sould be a success' do
      travel_to Time.zone.now

      session = Minitest::Mock.new
      session.expect :[]=, :return_value, [:user_id, users(:hr_admin).id]
      session.expect :[]=, :return_value, [:expires_at, 8.hours.from_now.to_i]

      result = Sessions::LogUserIn.call(session: session, user: users(:hr_admin))
      assert result.success?
    end

    test 'user gets logged in successfully via the session object passed in' do
      travel_to Time.zone.now

      session = Minitest::Mock.new
      session.expect :[]=, :return_value, [:user_id, users(:hr_admin).id]
      session.expect :[]=, :return_value, [:expires_at, 8.hours.from_now.to_i]

      Sessions::LogUserIn.call!(session: session, user: users(:hr_admin))
      session.verify
    end
  end
end
