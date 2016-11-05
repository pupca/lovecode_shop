class Configurator
  class << self
    # Subclasses need to initialize their own class-level instance variables
    def inherited(subclass)
      subclass.class_eval do
        # Class variable holding all the settings
        @settings = {}
      end
    end

    # Use as follows:
    #
    # configure do
    #   set :something, "some value"
    #   set :whatever,  "whatever value"
    # end
    #
    # configure :development do
    #   set :some_production_value, 1234
    # end
    #
    # configure :test do
    #   set :some_production_value, 1234
    # end
    #
    # configure :production do
    #   set :some_production_value, 1234
    # end
    #
    # configure :development, :test do
    #   set :some_common_value, 1234
    # end
    def configure(*environments, &block)
      return unless environments.empty? ||
                    environments.include?(ENV['RACK_ENV'].to_sym)
      instance_eval(&block)
    end

    # set :something, "some value"
    # This will also make a getter, so you can call Settings.something outside of this class.
    def set(key, value)
      @settings[key] = value
      define_getter(key)
    end

    # const :something, "some value"
    # Setted value is automatically deep freezed
    # This will also make a getter, so you can call Settings.something outside of this class.
    def const(key, value)
      @settings[key] = IceNine.deep_freeze(value)
      define_getter(key)
    end

    # Define a getter method so we can call this outside of this class:
    #
    # Settings.database # => #<Database object>
    def define_getter(key)
      define_singleton_method(key) do
        @settings[key]
      end unless method_defined?(key)
    end

    # Build database url
    #
    # @param [Hash] opts
    #   [String] host
    #   [Fixnum] port
    #   [String] database
    #   [String] user
    #   [String] password
    #   [Boolean] ssl
    #
    # @return [String] database url
    def jdbc_db_url(opts = {})
      if opts.empty? && ENV['DATABASE_URL']
        uri = URI(ENV['DATABASE_URL'])
        opts = {
          host: uri.host,
          port: uri.port,
          database: uri.path,
          user: uri.user,
          password: uri.password,
          ssl: true,
          sslfactory: 'org.postgresql.ssl.NonValidatingFactory'
        }
      else
        fail(ArgumentError, 'Database must be specified') unless opts[:database]
        opts = { host: 'localhost', port: 5432 }.merge!(opts)
      end

      url = File.join(
        "jdbc:postgresql://#{opts.delete(:host)}:#{opts.delete(:port)}",
        opts.delete(:database)
      )
      url << "?#{opts.map { |key, value| "#{key}=#{value}" }.join('&')}" unless opts.empty?
      url
    end

    def load_dependencies(pattern)
      Dir[root_path.join(pattern)].each { |file_path| require file_path }
    end

    def env
      ENV['RACK_ENV']
    end

    def app_component
      ENV['APP_COMPONENT']
    end

    def development?
      env == 'development'
    end

    def test?
      env == 'test'
    end

    def production?
      env == 'production'
    end

    def stage_server?
      production? && ENV['STAGE_ENVIRONMENT']
    end

    def production_server?
      production? && !ENV['STAGE_ENVIRONMENT']
    end

    def web?
      app_component == 'web'
    end

    def worker?
      app_component == 'worker'
    end
  end
end
