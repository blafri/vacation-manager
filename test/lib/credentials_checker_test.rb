# frozen_string_literal: true

require "test_helper"

# Test the credential checker
class CredentialsCheckerTest < ActiveSupport::TestCase
  test '#key_present? should return false if key not present in credentials' do
    checker = CredentialsChecker.new
    assert_not checker.key_present?(:missing_value)
  end

  test '#key_present? should return true if key present in credentials' do
    checker = CredentialsChecker.new
    assert checker.key_present?(:secret_key_base)
  end

  test '::require_keys! returns true if keys present' do
    assert CredentialsChecker.require_keys!(:secret_key_base, :password)
  end

  test '::require_keys! throws error if keys missing' do
    assert_raises(CredentialsChecker::KeyMissingError) do
      CredentialsChecker.require_keys!(:secret_key_base, :missing_value)
    end
  end
end
