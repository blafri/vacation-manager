# frozen_string_literal: true

require "test_helper"

# test for ValidateContext interactor
class LoginUserViaAzureIdTokenContractTest < ActiveSupport::TestCase
  def setup
    @contract = LoginUserViaAzureIdTokenContract.new
    @session = Minitest::Mock.new
    @session.expect :is_a?, true, [ActionDispatch::Request::Session]
  end

  test 'should be a success with valid input' do
    result = @contract.call({ session: @session, stored_state: 'random_string',
                              id_token: 'token string', state: 'random_string' })
    assert result.success?
  end

  test 'should not be a success if error key is present' do
    expected = { nil => ['Authentication failed: access denied'] }

    result = @contract.call({ session: @session, stored_state: 'random_string',
                              error: 'access denied' })
    assert_not result.success?
    assert_equal expected, result.errors.to_h
  end

  test 'should ensure id_token and state are present if error key is missing' do
    expected = { id_token: ['is missing'], state: ['is missing'] }

    result = @contract.call({ session: @session, stored_state: 'random_string' })
    assert_not result.success?
    assert_equal expected, result.errors.to_h
  end

  test 'it should validate the state' do
    expected = { state: ['is invalid'] }

    result = @contract.call({ session: @session, stored_state: 'random_string',
                              id_token: 'token string', state: 'differnet random_string' })
    assert_not result.success?
    assert_equal expected, result.errors.to_h
  end
end
