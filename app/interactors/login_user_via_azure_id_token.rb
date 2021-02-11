# frozen_string_literal: true

# Public: Use this interactor to log a user in using an ID Token from Azure AD. To see the required
# context values check the contract for this interactor.
class LoginUserViaAzureIdToken
  include Interactor::Organizer

  before do
    context.contract = LoginUserViaAzureIdTokenContract.new
  end

  organize ValidateContext,
           Sessions::VerifyAzureIdToken,
           Sessions::CreateOrUpdateUserFromAzureTokenClaims,
           Sessions::LogUserIn
end
