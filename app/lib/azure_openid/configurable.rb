# frozen_string_literal: true

module AzureOpenid
  # Public: This module contains methods used to get openid configuration metadata for Azure AD
  module Configurable
    class FetchSigningKeysError < StandardError; end

    class FetchOpenidConfigError < StandardError; end

    private

    # Internal: Fetch the OpenID metadata document for Azure AD. It will be cached for 24 hours so
    # that a network request will not be required everytime it is needed. I used 24 hours as that
    # is what is set on the cache-control HTTP header when requesting the document.
    #
    # Returns a Hash containg the metadata obtained from Azure AD.
    def openid_config
      @openid_config ||= Rails.cache.fetch('azure_openid_metadata', cache_options) do
        fetch_openid_config
      end
    end

    # Internal: If there is a cache miss for the OpenID metadata document this command will make a
    # network request to get the data.
    #
    # Returns a Hash containg the metadata obtained from Azure AD.
    def fetch_openid_config
      JSON.parse(Net::HTTP.get(URI(openid_config_url)), symbolize_names: true)
    rescue JSON::ParserError
      raise FetchOpenidConfigError
    end

    # Internal: Builds the url using the azure_tenant_id in the encrypted credentials file.
    #
    # Returns a String representing the URL used for the OpenID configuration metadata.
    def openid_config_url
      tenant_id = Rails.application.credentials.azure_tenant_id
      "https://login.microsoftonline.com/#{tenant_id}/v2.0/.well-known/openid-configuration"
    end

    # Internal: Fetch the Azure AD JWKS file that will be used to verify the JWT token. It will be
    # cached for 24 hours so that a network request will not be required everytime it is needed. I
    # used 24 hours as that is what is set on the cache-control HTTP header when requesting the
    # document.
    #
    # Returns a Hash of the JWKS data.
    def signing_keys
      @signing_keys ||= Rails.cache.fetch('azure_jwks_metadata', cache_options) do
        fetch_signing_keys
      end
    end

    # Internal: If there is a cache miss for the JWKS data for Azure AD this command will make a
    # network request to get the data.
    #
    # Returns a Hash of the JWKS data.
    def fetch_signing_keys
      JSON.parse(Net::HTTP.get(URI(openid_config[:jwks_uri])), symbolize_names: true)
    rescue JSON::ParserError
      raise FetchSigningKeysError
    end

    # Internal: The cache options used for caching the data returned from the network requests.
    def cache_options
      { expires_in: 1.day, race_condition_ttl: 10.seconds }
    end
  end
end
