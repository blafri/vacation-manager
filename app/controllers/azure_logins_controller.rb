# frozen_string_literal: true

# AzureLoginsController
class AzureLoginsController < ApplicationController
  include AzureOpenid::Configurable

  def create
    redirect_to authorize_endpoint_url
  rescue FetchOpenidConfigError
    flash[:error] = 'Unable to get authorization url. Please try again later'
    redirect_to new_session_path
  end

  private

  def authorize_endpoint_url
    uri = URI(openid_config[:authorization_endpoint])
    uri.query = URI.encode_www_form(client_id: client_id,
                                    redirect_uri: sessions_url,
                                    response_mode: 'form_post',
                                    response_type: 'id_token',
                                    scope: 'openid profile email',
                                    state: new_state,
                                    nonce: new_nonce)
    uri.to_s
  end

  def client_id
    credentials.azure_client_id!
  end

  def new_state
    generate_uuid.tap { |nonce| add_state_cookie(nonce) }
  end

  def new_nonce
    generate_uuid.tap { |nonce| add_nonce_to_db(nonce) }
  end

  def add_state_cookie(nonce)
    cookies[:azure_login_state] = {
      value: nonce,
      expires: 5.minutes.from_now,
      domain: request.host,
      httponly: true,
      same_site: :none
    }
  end

  def credentials
    Rails.application.credentials
  end

  def generate_uuid
    SecureRandom.uuid
  end

  def add_nonce_to_db(nonce)
    AzureLoginNonce.create!(nonce_value: nonce)
  end
end
