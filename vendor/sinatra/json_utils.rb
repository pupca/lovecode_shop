require_relative 'status_codes'

module Sinatra
  module JSONUtils
    include StatusCodes

    # Make JSON response with specified status code
    #
    # @param [Fixnum] code
    #   Response code
    # @param [Object] object
    #   Object to be serialized to JSON and returned as response body
    def json(code, data = nil, meta = {})
      status code
      return unless data
      content_type :json
      body MultiJson.dump(data: data, meta: meta)
    end

    # Is it a request which prefers JSON response?
    def expects_json?
      # Must be stringified, as preffered_type returns Sinatra::Request::AcceptEntry object
      request.preferred_type.to_s == mime_type(:json)
    end

    # Is it a JSON response?
    def responds_with_json?
      response.content_type == mime_type(:json)
    end

    #########
    # HALTERS
    #########

    # Halt on bad request error
    def bad_request(opts)
      flow_halt BAD_REQUEST, opts
    end

    # Halt on authorization error
    def unauthorized(opts)
      flow_halt UNAUTHORIZED, opts
    end

    # Halt on accessibility error
    def forbidden(opts)
      flow_halt FORBIDDEN, opts
    end

    # Halt on missing resource error
    def not_found(opts)
      flow_halt NOT_FOUND, opts
    end

    # Halt on conflict error
    def conflict(opts)
      flow_halt CONFLICT, opts
    end

    # Halt on precondition failed error
    def precondition_failed(opts)
      flow_halt PRECONDITION_FAILED, opts
    end

    # Halt on internal server error
    def internal_server_error(opts)
      flow_halt INTERNAL_SERVER_ERROR, opts
    end

    # Halt on error
    #
    # @param [Fixnum] code
    #   Response code
    # @param [Hash] opts
    #   :message [String]
    #   :headers [Hash]
    def flow_halt(code, opts = {})
      headers = opts[:headers] || {}
      body = nil

      unless opts[:message].blank?
        content_type :json
        body = MultiJson.dump(error: { message: opts[:message] })
      end

      halt code, headers, body
    end
  end
end
