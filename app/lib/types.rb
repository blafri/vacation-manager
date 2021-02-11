# frozen_string_literal: true

# Custom types for use with dry-validations gem
module Types
  include Dry::Types()

  SessionCookie = Types::Instance(ActionDispatch::Request::Session)
end
