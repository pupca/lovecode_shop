require 'rack/body_proxy'

module Rack
  class PrettyLogger
    def initialize(app, opts = {})
      @app = app
      @logger = opts[:logger]
      @whitelisted_agents = Regexp.union(Array(opts[:whitelisted_agents]))
    end

    def call(env)
      began_at = Time.now

      status, headers, body = @app.call(env)
      headers = Utils::HeaderHash.new(headers)
      body = BodyProxy.new(body) { log(env, status, headers, began_at) }

      [status, headers, body]
    end

    private

    def log(env, status, headers, began_at)
      now             = Time.now
      sender          = env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_ADDR']
      agent           = env['HTTP_USER_AGENT'] if env['HTTP_USER_AGENT'] &&
                                                  env['HTTP_USER_AGENT'] =~ @whitelisted_agents
      method          = env['REQUEST_METHOD']
      path            = env['PATH_INFO']
      query           = env['QUERY_STRING']
      http_version    = env['HTTP_VERSION']
      status_code     = status.to_s[0..3]
      content_length  = headers['Content-Length'].to_i
      time_taken      = now - began_at

      msg = "#{sender} #{agent ? "[#{agent}]" : '-'} " \
            "\"#{method} #{path}#{!query.empty? ? "?#{query}" : ''} #{http_version}\" " \
            "#{status_code} " \
            "#{!content_length.zero? ? "#{content_length / 1024}kB" : '-'} " \
            "#{time_taken * 1000}ms\n"

      logger = @logger || env['rack.errors']

      # Standard library logger doesn't support write but it supports << which actually
      # calls to write on the log device without formatting
      if logger.respond_to?(:write)
        logger.write(msg)
      else
        logger << msg
      end
    end
  end
end
