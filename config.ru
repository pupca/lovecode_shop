require_relative 'web_init'
require_relative 'vendor/pretty_logger'
# require 'sidekiq/web'

use Rack::Parser, parsers: {
  'application/json' => proc { |data| MultiJson.load(data, symbolize_keys: true) }
}
use Rack::PrettyLogger

run Rack::URLMap.new '/'        => WebApplication
