require "test_helper"

class CredentialsCheckerTest < ActiveSupport::TestCase
  def setup
    # this sets up a custm EncryptedConfiguration object to inject into the initializer fo the test
    # it simply has two keys 'password' and 'api_key'
    @credentials =  ActiveSupport::EncryptedConfiguration
      .new(config_path: Rails.root.join('test', 'test_files', 'test_creds.yml.enc'),
           key_path: Rails.root.join('test', 'test_files', 'test_creds.key'),
           env_key: 'NOT_HERE',
           raise_if_missing_key: true)
  end

  test '#key_present? should return false if key not present in credentials' do
    checker = CredentialsChecker.new(credentials: @credentials)
    assert_not checker.key_present?(:missing_value)
  end

  test '#key_present? should return true if key present in credentials' do
    checker = CredentialsChecker.new(credentials: @credentials)
    assert checker.key_present?(:password)
  end

  test '::require_keys! returns true if keys present' do
    assert CredentialsChecker.require_keys!(:password, :api_key, credentials: @credentials)
  end

   test '::require_keys! throws error if keys missing' do
    assert_raises(CredentialsChecker::KeyMissingError) do
      CredentialsChecker.require_keys!(:password, :missing_value, credentials: @credentials)
    end
  end
end
