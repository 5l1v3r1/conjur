# frozen_string_literal: true

require 'authentication/webservices'

module Authentication
  ValidateSecurity = CommandClass.new(
    dependencies: {
      role_class: ::Authentication::MemoizedRole,
      logger: Rails.logger
    },
    inputs: %i(webservice account user_id)
  ) do

    def call
      # No checks required for default conjur authn
      return if default_conjur_authn?

      validate_account_exists
      validate_user_is_defined
      validate_user_has_access
    end

    private

    def default_conjur_authn?
      @webservice.authenticator_name ==
        ::Authentication::Common.default_authenticator_name
    end

    def validate_account_exists
      raise AccountNotDefined, @account unless account_admin_role
    end

    def validate_user_is_defined
      raise NotDefinedInConjur, @user_id unless user_role
    end

    def validate_user_has_access
      # Ensure user has access to the service
      has_access = user_role.allowed_to?('authenticate', webservice_resource)
      unless has_access
        @logger.debug("[OIDC] User '#{@user_id}' is not authorized to " \
          "authenticate with webservice '#{webservice_resource_id}'")
        raise NotAuthorizedInConjur, @user_id
      end
    end

    def user_role_id
      @user_role_id ||= @role_class.roleid_from_username(@account, @user_id)
    end

    def user_role
      @role_class[user_role_id]
    end

    def account_admin_role
      @role_class["#{@account}:user:admin"]
    end
  end
end
