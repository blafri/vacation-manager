# frozen_string_literal: true

require "test_helper"

# test for ValidateContext interactor
class ValidateContextTest < ActiveSupport::TestCase
  # contract for testing purposes
  class TestContract < Dry::Validation::Contract
    params do
      required(:age).filled(:integer)
      required(:name).filled(:string)
    end
  end

  test 'should be a success if the contract is valid' do
    result = ValidateContext.call(contract: TestContract.new, age: 10, name: 'blayne')

    assert result.success?
  end

  test 'should not be a success if the contract is invalid' do
    result = ValidateContext.call(contract: TestContract.new)

    assert_not result.success?
  end

  test 'should remove values from context that are not in contract' do
    result = ValidateContext.call(contract: TestContract.new, age: '10', name: 'blayne',
                                  invalid: 'will be removed')

    assert_nil result.invalid
  end

  test 'should coerce values in context to the type specified in the contract' do
    result = ValidateContext.call(contract: TestContract.new, age: '10', name: 'blayne')

    assert_instance_of Integer, result.age
  end

  test 'should create error key in context' do
    expected = { age: ["is missing"], name: ["is missing"] }

    result = ValidateContext.call(contract: TestContract.new)
    assert_equal expected, result.errors
  end
end
