require './vendor/configurator'

class Settings < Configurator
  class << self
    ###############
    # Configurators
    ###############

    def configure_sequel
      # `max_connections` must match concurrency configuration, check `Procfile` for current setup
      db = Sequel.connect ENV['DATABASE_URL'],
      encoding: 'utf-8',
      logger: (respond_to?(:database_logger) ? database_logger : nil),
      max_connections: ENV['POOL_SIZE'].to_i

      # http://sequel.jeremyevans.net/rdoc/classes/Sequel/Timezones.html
      # Globally sets:
      #   `application_timezone`: The timezone you want the application to use.This is the timezone
      #     that incoming times from the database and typecasting are converted to.
      #   `database_timezone`: The timezone for storage in the database. This is the timezone to
      #     which Sequel will convert timestamps before literalizing them for storage in the
      #     database. It is also the timezone that Sequel will assume database timestamp values are
      #     already in (if they don't include an offset).
      #   `typecast_timezone`: The timezone that incoming data that Sequel needs to typecast is
      #     assumed to be already in (if they don't include an offset).
      Sequel.default_timezone = :utc

      # db.pgt_counter_cache(:teams, :id, :users_count, :users, :team_id)

      set :database, db
    end
    
    def configure_pony
      return unless defined? Pony

      require './vendor/pony_express'

      Pony.options = {
        from: no_reply_email,
        reply_to: reply_to_email,
        headers: { 'Content-Type' => 'text/html' },
        via: :smtp,
        via_options: {
          user_name: ENV['SENDGRID_USERNAME'],
          password: ENV['SENDGRID_PASSWORD'],
          address: 'smtp.sendgrid.net',
          port: '587',
          domain: 'heroku.com',
          authentication: :plain,
          enable_starttls_auto: true
        }
      }
    end

    def configure_sockets
      set :sockets, []
    end

    def get_freemails
      set :freemails, JSON.parse(File.read("config/freemails.json"))
    end

    def configure_multi_json
      MultiJson.dump_options = {
        date_format: 'yyyy-MM-dd\'T\'HH:mm:ss.SSSX',
        timezone: 'UTC',
        pretty: development?
      }

      MultiJson.load_options = {
        use_bigdecimal: false
      }
    end

    def configure_rollbar
      return unless defined? Rollbar

      Rollbar.configure do |config|
        config.access_token = ENV['ROLLBAR_ACCESS_TOKEN']
        config.disable_monkey_patch = true
        config.use_thread
      end
    end

    ###############################
    # App files & extension loaders
    ###############################

    def load_core_extensions
      require 'ice_nine/core_ext/object'
      load_dependencies 'vendor/core_extensions/*.rb'
    end

    def load_sequel_extensions
      load_dependencies 'vendor/sequel/**/*.rb'
    end

    def load_sinatra_extensions
      load_dependencies 'vendor/sinatra/*.rb'
    end

    def load_models
      load_dependencies 'models/*.rb'
    end

    def load_representers
      load_dependencies 'representers/*.rb'
    end

    def load_workers
      load_dependencies 'workers/**/*.rb'
    end
  end

  #################################
  # Environment based configuration
  #################################

  # configure :test do
  #   set :database_url, jdbc_db_url(database: 'beam_front_test')
  # end

  # configure :development do
  #   set :database_url, jdbc_db_url(database: 'beam_front')
  #   # set :database_logger, Logger.new($stdout)
  # end

  # configure :production do
  #   set :database_url, jdbc_db_url
  # end

  configure do
    const :root_path, Pathname.new(File.expand_path('../..', __FILE__))

    const :app_name, 'Beam Front'
    const :admin_credentials, [%w(admin beam#Psw1)]

    set :min_required_client_version, Gem::Version.new('0.0.1')

    const :no_reply_email, 'Beam <noreply@beam.ai>'
    const :reply_to_email, 'Beam <info@beam.ai'
    const :support_email, 'Beam <feedback@beam.ai>'

    
    configure_sequel
    configure_sockets
    configure_multi_json
    configure_rollbar
    # get_freemails
    configure_pony

    CarrierWave.configure do |config|
      config.root = File.dirname(__FILE__) + "/../public"
    end

    CarrierWave.configure do |config|
  config.fog_credentials = {
    provider:              'AWS',                        # required
    aws_access_key_id:     ENV['AWSAccessKeyId'],                        # required
    aws_secret_access_key: ENV['AWSSecretKey'],                        # required
    region:                'eu-west-1'
  }
  config.fog_directory  = 'codelove-stor'                          # required
  config.fog_public     = true
end


  end
end
