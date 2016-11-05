module Sinatra
  module WardenHelper
    # Shorthand to get Warden object
    def warden
      env['warden']
    end

    # Shorthand to get Warden options
    def warden_options
      env['warden.options']
    end

    # Shorthand to get current user
    def current_user
      warden.user
    end

    # Require authorization for an action
    #
    # @param [String] path to redirect to if user is unauthenticated
    def authorize!(failure_path = nil)
      return if warden.authenticated?

      session[:return_to] = request.path if request.request_method == 'GET'
      redirect(failure_path)
    end

    # Check if user's scope is matching expectations (all defined must match)
    def scope(*scopes)
      return if scopes.empty?

      unauthorized message: 'User must me authorized' unless current_user
      forbidden messages: 'Not all scope expectations are matched' unless
          current_user.grants_scope?(*scopes)
    end
  end
end
