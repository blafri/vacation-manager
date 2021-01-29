# frozen_string_literal: true

require 'test_helper'

module Sessions
  # test for Sessions::VerifyAzureIdToken interactor
  # rubocop:disable Metrics/ClassLength
  class VerifyAzureIdTokenTest < ActiveSupport::TestCase
    setup do
      stub_request(:get, openid_config_url)
        .to_return(body: file_fixture('openid_metadata.json').open, status: 200)

      stub_request(:get, 'https://login.microsoftonline.com/azure-tenant-id/discovery/v2.0/keys')
        .to_return(body: file_fixture('jwks_data.json').open, status: 200)

      @jwk = JWT::JWK.new(OpenSSL::PKey::RSA.new(file_fixture('rsa_2048.pem').read))

      @valid_headers = { kid: @jwk.kid, typ: 'JWT' }

      @valid_payload = {
        exp: 5.minutes.from_now.to_i,
        nbf: 5.minutes.ago.to_i,
        iat: 5.minutes.ago.to_i,
        iss: 'https://login.microsoftonline.com/azure-tenant-id/v2.0',
        aud: Rails.application.credentials.azure_client_id!,
        nonce: azure_login_nonces(:valid).nonce_value
      }
    end

    def openid_config_url
      tenant_id = Rails.application.credentials.azure_tenant_id!
      "https://login.microsoftonline.com/#{tenant_id}/v2.0/.well-known/openid-configuration"
    end

    test 'shoud be a success with a valid token' do
      id_token = JWT.encode(@valid_payload, @jwk.keypair, 'RS256', @valid_headers)
      result = Sessions::VerifyAzureIdToken.call(id_token: id_token)
      assert result.success?
    end

    test 'should not be a success with expired token' do
      @valid_payload[:exp] = 1.second.ago.to_i
      expected = { nil => ['Invalid ID Token: #<JWT::ExpiredSignature: Signature has expired>'] }

      id_token = JWT.encode(@valid_payload, @jwk.keypair, 'RS256', @valid_headers)
      result = Sessions::VerifyAzureIdToken.call(id_token: id_token)
      assert_not result.success?
      assert_equal expected, result.errors
    end

    test 'should not be a success with nbf in the future' do
      @valid_payload[:nbf] = 1.minute.from_now.to_i
      error_text = 'Invalid ID Token: #<JWT::ImmatureSignature: Signature nbf has not been reached>'

      id_token = JWT.encode(@valid_payload, @jwk.keypair, 'RS256', @valid_headers)
      result = Sessions::VerifyAzureIdToken.call(id_token: id_token)
      assert_not result.success?
      assert_equal({ nil => [error_text] }, result.errors)
    end

    test 'should not be a success with iat in the future' do
      @valid_payload[:iat] = 1.minute.from_now.to_i
      error_text = 'Invalid ID Token: #<JWT::InvalidIatError: Invalid iat>'

      id_token = JWT.encode(@valid_payload, @jwk.keypair, 'RS256', @valid_headers)
      result = Sessions::VerifyAzureIdToken.call(id_token: id_token)
      assert_not result.success?
      assert_equal({ nil => [error_text] }, result.errors)
    end

    test 'should not be a success with invalid issuer' do
      @valid_payload[:iss] = 'invalid issuer'
      error_text = 'Invalid ID Token: #<JWT::InvalidIssuerError: Invalid issuer. Expected ' \
                   'https://login.microsoftonline.com/azure-tenant-id/v2.0, received invalid ' \
                   'issuer>'

      id_token = JWT.encode(@valid_payload, @jwk.keypair, 'RS256', @valid_headers)
      result = Sessions::VerifyAzureIdToken.call(id_token: id_token)
      assert_not result.success?
      assert_equal({ nil => [error_text] }, result.errors)
    end

    test 'should not be a success with invalid audience' do
      @valid_payload[:aud] = 'invalid audience'
      error_text = 'Invalid ID Token: #<JWT::InvalidAudError: Invalid audience. Expected ' \
                   "#{Rails.application.credentials.azure_client_id!}, received invalid audience>"

      id_token = JWT.encode(@valid_payload, @jwk.keypair, 'RS256', @valid_headers)
      result = Sessions::VerifyAzureIdToken.call(id_token: id_token)
      assert_not result.success?
      assert_equal({ nil => [error_text] }, result.errors)
    end

    test 'should not be a success if nonce missing from token' do
      @valid_payload.delete(:nonce)
      error_text = 'Invalid Token Nonce: Nonce not in database'

      id_token = JWT.encode(@valid_payload, @jwk.keypair, 'RS256', @valid_headers)
      result = Sessions::VerifyAzureIdToken.call(id_token: id_token)
      assert_not result.success?
      assert_equal({ nil => [error_text] }, result.errors)
    end

    test 'should not be a success if nonce not in database' do
      @valid_payload[:nonce] = 'not in the db'
      error_text = 'Invalid Token Nonce: Nonce not in database'

      id_token = JWT.encode(@valid_payload, @jwk.keypair, 'RS256', @valid_headers)
      result = Sessions::VerifyAzureIdToken.call(id_token: id_token)
      assert_not result.success?
      assert_equal({ nil => [error_text] }, result.errors)
    end

    test 'should not be a success if nonce has expired' do
      @valid_payload[:nonce] = azure_login_nonces(:expired).nonce_value
      error_text = 'Invalid Token Nonce: Nonce has expired'

      id_token = JWT.encode(@valid_payload, @jwk.keypair, 'RS256', @valid_headers)
      result = Sessions::VerifyAzureIdToken.call(id_token: id_token)
      assert_not result.success?
      assert_equal({ nil => [error_text] }, result.errors)
    end

    test 'should not be a success if payload was altered' do
      error_text = 'Invalid ID Token: #<JWT::VerificationError: Signature verification raised>'

      id_token = JWT.encode(@valid_payload, @jwk.keypair, 'RS256', @valid_headers)
      id_token.sub!('.', '.altered')
      result = Sessions::VerifyAzureIdToken.call(id_token: id_token)
      assert_not result.success?
      assert_equal({ nil => [error_text] }, result.errors)
    end

    test 'should not be a success if signed with invalid key' do
      error_text = 'Invalid ID Token: #<JWT::VerificationError: Signature verification raised>'

      id_token = JWT.encode(@valid_payload,
                            OpenSSL::PKey::RSA.new(file_fixture('rsa_2048_wrong.pem').read),
                            'RS256', @valid_headers)
      id_token.sub!('.', '.altered')
      result = Sessions::VerifyAzureIdToken.call(id_token: id_token)
      assert_not result.success?
      assert_equal({ nil => [error_text] }, result.errors)
    end

    test 'should not be a success if can not find kid that matches the key it was signed with' do
      error_text = 'Invalid ID Token: #<JWT::DecodeError: Could not find public key for kid ' \
                   '4ee40255b12f426b450905322122963fcb3e30f940c8e7b37116df7e0f3fbc2a>'

      jwk = JWT::JWK.new(OpenSSL::PKey::RSA.new(file_fixture('rsa_2048_wrong.pem').read))

      id_token = JWT.encode(@valid_payload, jwk.keypair, 'RS256', { kid: jwk.kid, typ: 'JWT' })
      id_token.sub!('.', '.altered')
      result = Sessions::VerifyAzureIdToken.call(id_token: id_token)
      assert_not result.success?
      assert_equal({ nil => [error_text] }, result.errors)
    end

    test 'should not be a success if kid is missing from header' do
      @valid_headers.delete(:kid)
      error_text = 'Invalid ID Token: #<JWT::DecodeError: No key id (kid) found from token headers>'

      id_token = JWT.encode(@valid_payload, @jwk.keypair, 'RS256', @valid_headers)
      result = Sessions::VerifyAzureIdToken.call(id_token: id_token)
      assert_not result.success?
      assert_equal({ nil => [error_text] }, result.errors)
    end

    test 'should not be a success if can not retrieve openid metadata document' do
      stub_request(:get, openid_config_url).to_return(status: 500)
      error_text = 'Unable to fetch azure openid connect metadata document'

      id_token = JWT.encode(@valid_payload, @jwk.keypair, 'RS256', @valid_headers)
      result = Sessions::VerifyAzureIdToken.call(id_token: id_token)
      assert_not result.success?
      assert_equal({ nil => [error_text] }, result.errors)
    end

    test 'should not be a success if can not retrieve jwks document' do
      stub_request(:get, 'https://login.microsoftonline.com/azure-tenant-id/discovery/v2.0/keys')
        .to_return(status: 500)
      error_text = 'Unable to fetch azure JWKS document'

      id_token = JWT.encode(@valid_payload, @jwk.keypair, 'RS256', @valid_headers)
      result = Sessions::VerifyAzureIdToken.call(id_token: id_token)
      assert_not result.success?
      assert_equal({ nil => [error_text] }, result.errors)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
