# frozen_string_literal: true

require 'types'

module Authentication
  class AuthenticatorInput < ::Dry::Struct

    attribute :authenticator_name, ::Types::NonEmptyString
    attribute :service_id, ::Types::NonEmptyString.optional
    attribute :account, ::Types::NonEmptyString
    attribute :username, ::Types::NonEmptyString.optional
    attribute :password, ::Types::String.optional
    attribute :origin, ::Types::NonEmptyString
    attribute :request, ::Types::Any

    # Creates a copy of this object with the attributes updated by those
    # specified in hash
    #
    def update(hash)
      self.class.new(to_hash.merge(hash))
    end

    # Convert this Input to a Security::AccessRequest
    #
    def to_access_request(enabled_authenticators)
      ::Authentication::Security::AccessRequest.new(
        webservice:              webservice,
        whitelisted_webservices: ::Authentication::Webservices.from_string(
          self.account,
          enabled_authenticators || Authentication::Common.default_authenticator_name
        ),
        user_id:                 self.username
      )
    end

    def webservice
      @webservice ||= ::Authentication::Webservice.new(
        account:            self.account,
        authenticator_name: self.authenticator_name,
        service_id:         self.service_id
      )
    end
  end
end
