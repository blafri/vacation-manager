# frozen_string_literal: true

# Controller to handle user dashboard
class DashboardsController < ApplicationController
  include SecurableController

  before_action :authenticate_user!

  def show
    @session_data = session.to_h
  end
end
