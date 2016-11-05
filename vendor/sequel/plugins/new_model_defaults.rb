module Sequel
  module Plugins
    # Adds an new_model_defaults hook to models, called after initializing new objects
    #
    # Usage:
    #
    #   # Make all model subclasses support the new_model_defaults hook
    #   Sequel::Model.plugin :new_model_defaults
    #
    #   # Make the Album class support the new_model_defaults hook
    #   Album.plugin :new_model_defaults
    module NewModelDefaults
      module InstanceMethods
        # Call new_model_defaults for new model objects.
        def initialize(h = {})
          super
          new_model_defaults
        end

        # An empty new_model_defaults hook, so that plugins that use this
        # can always call super to get the default behavior.
        def new_model_defaults
        end
      end
    end
  end
end
