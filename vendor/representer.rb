require_relative 'representable_dataset'

class Representer
  # Maps models to representers.
  #
  #   {
  #      PostMedium => PostMediumRepresenter,
  #      PostPhoto  => PostPhotoRepresenter,
  #      PostVideo  => PostVideoRepresenter,
  #      # ...
  #    }
  #
  # @return [Hash<Sequel::Model, Representer>]
  @@representers = {} # rubocop:disable Style/ClassVars

  class << self
    #################
    # Declarative API
    #################

    # Store dataset modifier proc.
    #
    #   class SomeRepresenter < Representer
    #     dataset_modifier :parent do |ds|
    #       ds.select_prepend(
    #         :posts__id, :posts__type, :posts__data, :posts__created_at, :posts__replies_count
    #       )
    #     end
    #
    #     dataset_modifier :parent, :child do |ds|
    #       # ...
    #     end
    #   end
    #
    # @param [Array<Symbol>] modes
    def dataset_modifier(*modes, &block)
      modes.each do |mode|
        @modes[mode] ||= {}
        @modes[mode][:modifier] = block
      end
    end

    # Store representation proc.
    #
    #   class SomeRepresenter < Representer
    #     mode :parent do |post, repre|
    #       repre.set(
    #         id:            post.fetch(:id),
    #         type:          post.fetch(:type),
    #         created_at:    post.fetch(:created_at),
    #         replies_count: post.fetch(:replies_count)
    #       )
    #     end
    #
    #     mode :parent, :child do |post, repre|
    #       repre.set(
    #         # ...
    #       )
    #     end
    #   end
    #
    # @param [Array<Symbol>] modes
    def mode(*modes, &block)
      modes.each do |mode|
        @modes[mode] ||= {}
        @modes[mode][:function] = block
      end
    end

    # Store a pagination block under +name+ key for later.
    #
    # Classic offset-based pagination:
    #
    #   class SomeRepresenter < Representer
    #     paginator :offset do |rds, params|
    #       limit  = [params.fetch(:limit, PAGE_SIZE).to_i, MAX_PAGE_SIZE].min
    #       offset = params.fetch(:offset, 0).to_i
    #
    #       rds.load do |ds|
    #         ds.order(:id).limit(limit).offset(offset)
    #       end
    #
    #       rds.next_page_params = { limit: limit, offset: offset + limit } if
    #         rds.size == limit
    #
    #       rds.prev_page_params = { limit: limit, offset: [offset - limit, 0].max } if
    #         offset > 0
    #     end
    #   end
    #
    # Usage:
    #
    #   posts = Post.dataset.represent_as(:parent, paginate_with: :offset)
    #
    #   posts.next_page?       # => true
    #   posts.prev_page?       # => false
    #   posts.next_page_params # => { limit: 10, offset: 10 }
    #   posts.prev_page_params # => nil
    #
    #   pagination = { limit: 10, offset: 50 }
    #   posts = Post.dataset.represent_as(:parent, paginate_with: :offset, pagination: pagination)
    #
    #   posts.next_page?       # => true
    #   posts.prev_page?       # => true
    #   posts.next_page_params # => { limit: 10, offset: 60 }
    #   posts.prev_page_params # => { limit: 10, offset: 40 }
    #
    # ID-based (marker) pagination:
    #
    #   class SomeRepresenter < Representer
    #     paginator :marker do |rds, params|
    #       limit = [params.fetch(:limit, PAGE_SIZE).to_i, MAX_PAGE_SIZE].min
    #
    #       rds.load do |ds|
    #         ds = ds.where(Sequel.expr(:id) < params[:until_id]) if params[:until_id]
    #         ds = ds.where(Sequel.expr(:id) > params[:since_id]) if params[:since_id]
    #         ds.order(:id).limit(limit)
    #       end
    #
    #       rds.next_page_params = {
    #         limit: limit,
    #         since_id: rds.items.last.id
    #       } if rds.present? && rds.size == limit
    #     end
    #   end
    #
    # Usage:
    #
    #   pagination = { limit: 10, since_id: 300 }
    #   posts = Post.dataset.represent_as(:parent, paginate_with: :marker, pagination: pagination)
    #
    #   posts.next_page?       # => true
    #   posts.prev_page?       # => true
    #   posts.next_page_params # => { limit: 10, since_id: 310 }
    #   posts.prev_page_params # => { limit: 10, until_id: 301 }
    #
    #   pagination = { limit: 10, since_id: 740 }
    #   posts = Post.dataset.represent_as(:parent, paginate_with: :marker, pagination: pagination)
    #
    #   posts.next_page?       # => false
    #   posts.prev_page?       # => true
    #   posts.next_page_params # => nil
    #   posts.prev_page_params # => { limit: 10, until_id: 741 }
    def paginator(name, &block)
      @paginators[name] = block
    end

    # Specify helper methods for this class
    #
    #   class SomeRepresenter < Representer
    #     helpers do
    #       def stringify(obj)
    #         obj.to_s
    #       end
    #     end
    #
    #     mode :list do |post, repre|
    #       repre.id = stringify(post.id)
    #       repre.format_date do |date|
    #         # ...
    #       end
    #     end
    #   end
    def helpers(&block)
      # Attach those methods on the class object, not instance object,
      # as if def +self.stringify+.
      instance_eval(&block)
    end

    # Register a plugin. It takes a module as a parameter and tries to find
    # +Paginators+ in it. If it's there, it pulls in all methods and
    # registers a paginator for each one with the same name as them method
    # name.
    #
    #   module UsefulPlugin
    #     module Paginators
    #       def marker_asc(rds, params)
    #         limit = [params.fetch(:limit, PAGE_SIZE).to_i, MAX_PAGE_SIZE].min
    #
    #         rds.load do |ds|
    #           ds = ds.where(Sequel.expr(:id) < params[:until_id]) if params[:until_id]
    #           ds = ds.where(Sequel.expr(:id) > params[:since_id]) if params[:since_id]
    #           ds.order(:id).limit(limit)
    #         end
    #
    #         rds.next_page_params = {
    #           limit: limit,
    #           since_id: rds.items.last.id
    #         } if rds.present? && rds.size == limit
    #       end
    #     end
    #   end
    #
    #   class SomeRepresenter < Representer
    #     plugin UsefulPlugin
    #   end
    #
    # @param [Module] plugin_module
    def plugin(plugin_module)
      plugin_paginators(plugin_module)
    end

    #############
    # Regular API
    #############

    # Turn a model instance (or model instance collection) into a representation
    # object.
    #
    # @param [Sequel::Dataset, Sequel::Model] object
    # @param [Symbol] mode
    # @param [Hash] opts
    #   (Symbol) paginate_with: paginator name, eg +:api+, +:admin+ etc.
    #   (Hash)   pagination: pagination parameters, eg +:page+, +:since_id+ or +:until_id+
    # @param [Object] context Extra options to be passed to each +mode+
    #
    # @return [RepresentableDataset, Sequel::Model]
    def represent_as(object, mode, opts: nil, context: nil)
      raise(ArgumentError, 'Provided mode is not supported') unless support?(mode)

      if object.is_a?(Sequel::Dataset)
        # Load all objects in dataset and represent them
        represent_dataset(object, mode, opts: opts, context: context)
      else
        raise(ArgumentError, 'Only Sequel::Dataset can be paginated') if opts
        # Represent single object
        represent_object(object, mode, context: context)
      end
    end

    # Modify the dataset with the proc stored in the representer.
    #
    #   User.dataset.modify_with(:simple).all
    #
    # @param [Sequel::Dataset] dataset
    # @param [Symbol] mode
    #
    # @return [Sequel::Dataset]
    def modify_with(dataset, mode)
      raise(ArgumentError, 'Provided mode is not supported') unless support?(mode)
      raise(ArgumentError, 'No such modifier found') unless @modes[mode][:modifier]

      @modes[mode][:modifier].call(dataset)
    end

    # Run the paginator block for the given dataset and name.
    # Pass in the pagination params.
    #
    #   User.dataset.paginate_with(:marker, pagination: { since_id: 5 })
    #
    # @return [RepresentableDataset]
    def paginate_with(dataset, name, pagination)
      rds  = RepresentableDataset.new(dataset)
      opts = {
        paginate_with: name,
        pagination:    pagination
      }

      paginate(rds, opts)
    end

    #######################
    # Helpful class methods
    #######################

    # Find corresponding model for a representer.
    #
    # @param [Representer] representer
    #
    # @return [Sequel::Model]
    def model_for(representer)
      model_class_string = representer.to_s.chomp('Representer')
      Object.const_get(model_class_string)
    end

    # Find corresponding representer for a model.
    #
    # @param [Sequel::Model] model
    #
    # @return [Representer]
    def representer_for(model)
      @@representers[model] || raise(ArgumentError, "Representer for #{model} not found")
    end

    # Fetch the function from @modes[mode][:function].
    #
    # @param [Symbol] mode
    #
    # @return [Proc]
    def representer_proc_for(mode)
      @modes.fetch(mode).fetch(:function)
    end

    protected

    ###########
    # Internals
    ###########

    # When a class inherits from +Representer+, it needs to setup the
    # class-instance variables to store the various procs.
    def inherited(subclass)
      # Register the subclass in a lookup table (shared class variable).
      model                 = model_for(subclass)
      @@representers[model] = subclass

      # Setup class-instance variables.
      subclass.class_eval do
        @modes      = {}
        @paginators = {}
        @helpers    = {}
      end
    end

    # Pulls in all methods in a Paginators
    # submodule and registers a paginator for each method.
    #
    # Convenience method.
    #
    # @param [Module] plugin_module
    def plugin_paginators(plugin_module)
      return unless plugin_module.const_defined?(:Paginators)

      # Get the submodule.
      paginators_submodule = plugin_module::Paginators

      # Get all the method names defined there.
      paginators_methods = paginators_submodule.instance_methods

      return if paginators_methods.empty?

      # Pull them in so they can get called on self.
      extend(paginators_submodule)

      # For each method define a paginator with the same name
      # as the method. When called, simply call the "extended" method
      # now available on self with the same arguments.
      paginators_methods.each do |method_symbol|
        paginator method_symbol do |rds, params|
          send(method_symbol, rds, params)
        end
      end
    end

    # Can this representer be represented as +mode+?
    #
    # @return [Bool]
    def support?(mode)
      @modes.keys.include?(mode)
    end

    # Wrap results in a +RepresentableDataset+. Also paginate if pagination is defined.
    #
    # @param [Sequel::Dataset] dataset
    # @param [Symbol] mode
    # @param [Hash] opts
    #   (Symbol) paginate_with: paginator name, eg +:api+, +:admin+ etc.
    #   (Hash)   pagination: pagination parameters, eg +:page+, +:since_id+ or +:until_id+
    #
    # @return [RepresentableDataset]
    def represent_dataset(dataset, mode, opts: nil, context: nil)
      dataset   = modify_with(dataset, mode) if @modes[mode][:modifier]
      repr_proc = representer_proc(dataset.model, mode)
      rds       = RepresentableDataset.new(dataset)

      # Paginate the dataset if pagination was passed.
      paginate(rds, opts) if opts

      # Map the dataset items into represented objects.
      rds.map! do |item|
        represented_object = RepresentedObject.new
        repr_proc.call(item, represented_object, context)
      end

      rds
    end

    # Wrap object in a +RepresentedObject+.
    #
    # @param [Sequel::Model] object
    # @param [Symbol] mode
    #
    # @return [RepresentableDataset]
    def represent_object(object, mode, context: nil)
      represented_object = RepresentedObject.new
      @modes[mode][:function].call(object, represented_object, context)
      represented_object
    end

    # We need to treat Single Table Inheritance dataset a bit differently.
    #
    # Normally we simply map over the dataset and call the current
    # +@modes[mode][:function]+.
    #
    # With STI, however, we need to first find the corresponding representer
    # for every row and call represent on him.
    #
    # @param [Sequel::Model] model
    # @param [Symbol] mode
    #
    # @return [Proc]
    def representer_proc(model, mode)
      repr_proc = if model.respond_to?(:sti_dataset)
                    lambda do |obj, repre|
                      representer = representer_for(obj.model)
                      representer.representer_proc_for(mode).call(obj, repre)
                    end
                  else
                    representer_proc_for(mode)
                  end

      repr_proc
    end

    # Find the corresponding paginator and paginate the results by calling it
    # with current dataset and passed-in params.
    #
    # Also wrap results in a RepresentableDataset.
    #
    # @param [RepresentableDataset] rds
    # @param [Hash] opts
    #   (Symbol) paginate_with: paginator name, eg +:api+, +:admin+ etc.
    #   (Hash)   pagination: pagination parameters, eg +:page+, +:since_id+ or +:until_id+
    #
    # @return [RepresentableDataset]
    def paginate(rds, opts)
      paginator_key  = opts[:paginate_with] || raise(ArgumentError, 'Missing :paginate_with option')
      pagination     = opts[:pagination] || {}
      paginator_proc = @paginators[paginator_key]

      unless paginator_proc
        paginator_keys = @paginators.keys.map(&:inspect).join(', ')
        msg = "Paginator #{paginator_key.inspect} not found"
        msg << ", available are #{paginator_keys}" if paginator_keys.present?
        raise(ArgumentError, msg)
      end

      # Run the pagination block
      paginator_proc.call(rds, pagination)

      rds
    end
  end
end
