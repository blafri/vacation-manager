# frozen_string_literal: true

require 'test_helper'

class SecurableControllerTest < ActionDispatch::IntegrationTest
  class TestController < ApplicationController
    include SecurableController

    before_action :authenticate_user!

    def new
      render inline: ''
    end
  end

  setup do
    Rails.application.routes.draw do
      root 'dashboards#show'
      get '/test', to: 'securable_controller_test/test#new', as: :test
      resources :sessions
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test 'redirects user to login page if not authenticated' do
    get test_url
    assert_redirected_to new_session_path
    assert_equal 'Please sign in before continuing.', flash[:alert]
  end

  test '#user_signed_in returns false if not authenticated' do
    get test_url
    assert_not @controller.user_signed_in?
  end

  test '#current_user returns nil if not authenticated' do
    get test_url
    assert_nil @controller.current_user
  end

  test 'allows access to the action if authenticated' do
    get test_login_url, params: { sign_in_as_user_id: users(:ordinary_user).id }

    get test_url
    assert_response :success
  end

  test '#user_signed_in restruns true if authenticated' do
    get test_login_url, params: { sign_in_as_user_id: users(:ordinary_user).id }

    get test_url
    assert @controller.user_signed_in?
  end

  test '#current_user returns the signed in user if authenticated' do
    get test_login_url, params: { sign_in_as_user_id: users(:ordinary_user).id }

    get test_url
    assert_equal users(:ordinary_user), @controller.current_user
  end
end
