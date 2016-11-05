require 'bundler'

ENV['RACK_ENV'] ||= 'development'
ENV['POOL_SIZE'] ||= ENV['PUMA_MAX_THREADS'] || '5'
ENV['APP_COMPONENT'] = 'web'

Bundler.require :default, :web, ENV['RACK_ENV']

# Application files
require_relative 'config/settings'

# Load app files
Settings.load_core_extensions
Settings.load_sequel_extensions
Settings.load_sinatra_extensions
Settings.load_models
Settings.load_representers
Settings.load_workers

require_relative 'web_app'
