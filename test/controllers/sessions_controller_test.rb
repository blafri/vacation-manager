# frozen_string_literal: true

require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test 'should be able to access this page if not logged in' do
    get new_session_url
    assert_response :success
  end

  test 'should get redirected to root path if already logged in' do
    get test_login_url, params: { sign_in_as_user_id: users(:ordinary_user).id }

    get new_session_url
    assert_redirected_to root_path
  end
end