# frozen_string_literal: true

require 'credentials_checker'

# Make sure all required credentials are present
CredentialsChecker.require_keys!(:secret_key_base, :azure_tenant_id, :azure_client_id)
