# frozen_string_literal: true

module Sessions
  # Internal: If the user can not be found in the database create the user from token claims. If the
  # user is in the database update his attributes based on the claims. The context keys expected
  # are as follows:
  #   claims - (required) The claims extracted from the token.
  #
  # Examples
  #
  #   Sessions::CreateOrUpdateUserFromAzureTokenClaims.call(claims: hash_of_token_claims)
  #   #=> Interactor::Context
  class CreateOrUpdateUserFromAzureTokenClaims
    include Interactor

    def call
      context.user = User.find_or_initialize_by(azure_id: claims['oid']).tap do |user|
        user.update!(email: fetch_claim('email', required: true),
                     full_name: fetch_claim('name', required: true),
                     roles: fetch_claim('roles', default: []))
      end
    end

    private

    # Internal: Fetches the supplied claim from claims hash. If required is set to true and the
    # claim does not exist in the hash or is nil/empty the context will fail indicating the key that
    # is required but not present. You can also set a default value for a key so that if it is not
    # found in the claims hash the default value will be returned.
    #
    # claim_key - (required) The claim to fetch from the hash.
    # required  - (optional) Set to true if the key is required to be present in the claims hash. If
    #             it is not present in the hash the context will fail.
    # default   - (optional) What to return if the claim is not present in the hash. If required is
    #             set to true this value will be ignored since the context will fail if a required
    #             key is not present.
    #
    # Returns value assigned to the key in the claims hash or fails the context if a required key is
    # not found.
    def fetch_claim(claim_key, required: false, default: nil)
      claim = claims[claim_key]

      if required == true && claim.blank?
        context.fail!(errors: { nil => ["Required claim #{claim_key} was not found"] })
      end

      claim.nil? ? default : claim
    end

    # Internal: Fetches the claims from the token from the context.
    #
    # Returns a Has of the token claims.
    def claims
      context.claims
    end
  end
end
