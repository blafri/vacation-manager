# frozen_string_literal: true

# Public: Contract to verify the parameters passed to LoginUserViaAzureIdToken interactor.
class LoginUserViaAzureIdTokenContract < Dry::Validation::Contract
  params do
    required(:session).filled(Types::SessionCookie)
    required(:stored_state).filled(:string)
    optional(:id_token).filled(:string)
    optional(:state).filled(:string)
    optional(:error).maybe(:string)
  end

  # Set error message if error is present
  rule(:error) do
    next unless key?

    base.failure("Authentication failed: #{value}")
  end

  # If error is not present id_token and state must be present
  rule(:error) do
    next if key?

    key(:id_token).failure('is missing') unless key?(:id_token)
    key(:state).failure('is missing') unless key?(:state)
  end

  # Validate the state if present
  rule(:state, :stored_state) do
    next unless key?

    key.failure('is invalid') if value != values[:stored_state]
  end
end
