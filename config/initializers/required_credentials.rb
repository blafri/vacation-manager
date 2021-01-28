require 'credentials_checker'

# Make sure all required credentials are present
CredentialsChecker.require_keys!(:secret_key_base)
