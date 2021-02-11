# frozen_string_literal: true

# Internal: Santitizes the context by running it through a contract powered by dry-validations and
# then replacing the entire context with the sanitized version for processing.
class ValidateContext
  include Interactor

  def call
    result = contract.call(context.to_h)
    context.fail!(errors: result.errors.to_h) unless result.success?

    prepare_context(result)
  end

  private

  def prepare_context(result)
    context.to_h.each_key { |key| context.delete_field(key) }

    result.to_h.each do |(attribute, value)|
      context.send("#{attribute}=", value)
    end
  end

  def contract
    context.contract
  end
end
