# frozen_string_literal: true

# Public: You can use this class to verify that configuration keys that you need to be present in
# your credentials file are present. The main way to use this class is by calling the class method
# require_keys! and suppling it with a list of keys that you need to be certain exist in the
# credentials file. If any of the keys listed are not present in the encrypted credentials file
# an error will be thrown indicating which key is missing. It is best to use this class in an
# initializer to cause your application to error on boot if any required configuration keys are
# missing.
#
# Example:
#
#   CredentialsChecker.require_keys!('secret_key_base', 'api_password', 'email_password')
class CredentialsChecker
  attr_reader :credentials

  class KeyMissingError < StandardError; end

  # Public: Checks the list of suppiled keys actual exists in the credentials file. If any are
  # missing it will throw an error indicating which key is missing.
  #
  # Examples
  #
  #   CredentialsChecker.require_keys!('secret_key_base', 'api_password', 'email_password')
  #
  # Retuns true if all keys are present or raises an error if any are missing.
  def self.require_keys!(*keys, **options)
    checker = new(options)

    keys.each do |key|
      raise KeyMissingError, "Missing Required key #{key}" unless checker.key_present?(key)
    end

    true
  end

  def initialize(credentials: Rails.application.credentials)
    @credentials = credentials
  end

  # Public: Checks if the supplied key is present in the encrypted credentials file.
  #
  # Returns true if it is present or false if it is missing or empty.
  def key_present?(key)
    result = credentials.public_send(key.to_sym)
    return false if result.blank?

    true
  end
end
