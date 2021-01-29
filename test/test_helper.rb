ENV['RAILS_ENV'] ||= 'test'
require_relative "../config/environment"
require "rails/test_help"
require 'minitest/autorun'
require 'webmock/minitest'

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

class TestLoginsController < ApplicationController
  def new
    session[:user_id] = params.require(:sign_in_as_user_id).to_i
    session[:expires_at] = 8.hours.from_now.to_i
    redirect_to(root_path)
  end
end

Rails.application.routes.append do
  get '/test_login', to: 'test_logins#new', as: :test_login
end
