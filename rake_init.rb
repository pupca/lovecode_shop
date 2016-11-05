require 'bundler'

ENV['RACK_ENV'] ||= 'development'
ENV['POOL_SIZE'] ||= ENV['WORKER_MAX_THREADS'] || '5'
ENV['APP_COMPONENT'] = 'worker'

Bundler.require :default, :worker, ENV['RACK_ENV']

require_relative 'config/settings'

Settings.load_core_extensions
Settings.load_sequel_extensions
Settings.load_sinatra_extensions
Settings.load_models
Settings.load_representers
Settings.load_workers

Dir[Settings.root_path.join 'modules/**/*.rb'].each { |module_path| require module_path }