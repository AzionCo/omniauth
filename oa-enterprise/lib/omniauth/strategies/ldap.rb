require 'omniauth/enterprise'
require 'net/ldap'

module OmniAuth
  module Strategies
    class LDAP
      include OmniAuth::Strategy
      
      autoload :Adaptor, 'omniauth/strategies/ldap/adaptor'
      
      def initialize(app, title, options = {})
        super(app, options.delete(:name) || :ldap)
        @title = title
        @adaptor = OmniAuth::Strategies::LDAP::Adaptor.new(options)
      end
      
      protected
      
      def request_phase
        if env['REQUEST_METHOD'] == 'GET'
          get_credentials
        else
          perform
        end
      end

			def get_credentials
        OmniAuth::Form.build(@title) do
          text_field 'Login', 'username'
          password_field 'Password', 'password'
        end.to_response
      end
      def perform
      	begin
      		@adaptor.bind(:bind_dn => request.POST['username'], :password => request.POST['password'])
      	rescue
      		fail!(:invalid_credentials)
      	end
        request.POST['auth'] = auth_hash
        @env['REQUEST_METHOD'] = 'GET'
        @env['PATH_INFO'] = "#{OmniAuth.config.path_prefix}/#{name}/callback"

        @app.call(@env)
      end      

      def callback_phase
      	fail!(:invalid_request)
      end
      
      def auth_hash
        OmniAuth::Utils.deep_merge(super, {
          'uid' => request.POST['username']
        })
      end
      
    end
  end
end