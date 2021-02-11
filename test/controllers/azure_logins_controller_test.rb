# frozen_string_literal: true

require "test_helper"

class AzureLoginsControllerTest < ActionDispatch::IntegrationTest
  def openid_config_url
    tenant_id = Rails.application.credentials.azure_tenant_id!
    "https://login.microsoftonline.com/#{tenant_id}/v2.0/.well-known/openid-configuration"
  end

  test 'should redirect you to the correct url' do
    stub_request(:get, openid_config_url)
      .to_return(body: file_fixture('openid_metadata.json').open, status: 200)

    client_id = Rails.application.credentials.azure_client_id!

    post azure_logins_url

    assert_redirected_to 'https://login.microsoftonline.com/azure-tenant-id/oauth2/v2.0/authorize' \
                         "?client_id=#{client_id}&" \
                         "redirect_uri=#{CGI.escape(sessions_url)}&" \
                         'response_mode=form_post&' \
                         'response_type=id_token&' \
                         "scope=#{CGI.escape('openid profile email')}&" \
                         "state=#{cookies[:azure_login_state]}&" \
                         "nonce=#{AzureLoginNonce.last.nonce_value}"
  end

  test 'should redirect to signin page if can not get authorization url' do
    stub_request(:get, openid_config_url).to_return(status: 500)

    post azure_logins_url

    assert_redirected_to new_session_path
  end

  test 'should flash message if can not get authorization url' do
    stub_request(:get, openid_config_url).to_return(status: 500)

    post azure_logins_url

    assert_equal 'Unable to get authorization url. Please try again later', flash[:error]
  end
end
