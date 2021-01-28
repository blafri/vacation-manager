class CredentialsChecker
  attr_reader :credentials

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

  def key_present?(key)
    result = credentials.public_send(key.to_sym)
    return false if result.blank?

    true
  end

  private

  class KeyMissingError < StandardError; end
end
