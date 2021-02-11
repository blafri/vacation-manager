# frozen_string_literal: true

module Sessions
  # Internal: Validates that the id token is a valid azure id token. The context keys expected are
  # as follows:
  #   id_token - (Required) The Azure ID Token to verify.
  #
  # Examples
  #
  #   Sessions::VerifyAzureIdToken.call(id_token: method_to_get_id_token)
  #   #=> Interactor::Context
  class VerifyAzureIdToken
    include Interactor
    include AzureOpenid::Configurable

    def call
      claims, _header = decode_token
      verify_nonce(claims['nonce'])
      context.claims = claims
    rescue FetchOpenidConfigError
      context.fail!(errors: { nil => ["Unable to fetch azure openid connect metadata document"] })
    rescue FetchSigningKeysError
      context.fail!(errors: { nil => ["Unable to fetch azure JWKS document"] })
    end

    private

    # Internal: Decode and verify the token using the jwt gem.
    #
    # Returns an Array with the first value containg a Hash of the decoded token payload/claims and
    # the second value containing a Hash of the decoded token headers.
    def decode_token
      JWT.decode(jwt, nil, true, decode_opts)
    rescue JWT::DecodeError => e
      context.fail!(errors: { nil => ["Invalid ID Token: #{e.inspect}"] })
    end

    # Internal: Options used to verify the authenticity of the token.
    #
    # Returns a Hash of the option to use with the jwt gem.
    # rubocop:disable Metrics/MethodLength
    def decode_opts
      {
        algorithm: 'RS256',
        verify_expiration: true,
        verify_not_before: true,
        verify_iat: true,
        verify_iss: true,
        iss: openid_config[:issuer],
        verify_aud: true,
        aud: client_id,
        jwks: signing_keys
      }
    end
    # rubocop:enable Metrics/MethodLength

    # Internal: Verifies that the nonce received in the token is a nonce that was stored in the db
    # due to a request for a token. Once the nonce is found in the DB it is deleted to prevent
    # replay attacks. The nonce is also checked that is was created recently and not a reply to a
    # request created a while ago.
    #
    # Returns nothing if the nonce is valid. If the nonce can not be found or is expired it will
    # raise an error to fail the context.
    def verify_nonce(token_nonce)
      db_nonce = AzureLoginNonce.find_by(nonce_value: token_nonce)
      invalid_nonce('Nonce not in database') if db_nonce.nil?

      # Remove nonce from database as it has been used
      db_nonce.destroy!

      return if db_nonce.created_at >= 5.minutes.ago

      invalid_nonce('Nonce has expired')
    end

    # Internal: Call this method if the nonce is valid to raise an error to fail the context.
    #
    # Returns nothing. It always raises an error to fail the context.
    def invalid_nonce(msg)
      context.fail!(errors: { nil => ["Invalid Token Nonce: #{msg}"] })
    end

    # Internal: Grap the client ID stored in the encrypted credentials file.
    #
    # Returns a String for the azure_client_id.
    def client_id
      credentials.azure_client_id
    end

    # Internal: Get the credentials object.
    #
    # Returns an ActiveSupport::EncryptedConfiguration object.
    def credentials
      Rails.application.credentials
    end

    # Internal: Grab the id token to verify from the context.
    #
    # Returns a String representing the ID token to verify.
    def jwt
      context.id_token
    end
  end
end
