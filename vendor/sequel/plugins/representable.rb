module Sequel
  module Plugins
    module Representable
      def self.apply(model, _opts = {})
        model.plugin SelectPrepend
      end

      class MissingAttributeError < StandardError; end

      module SharedMethods
        # Class which is responsible for representation
        #
        #   User.first.representer    # => UserRepresenter
        #   User.limit(5).representer # => UserRepresenter
        #
        # @return [Representer]
        def representer
          Representer.representer_for(model)
        end

        # Represent model with its representer
        #
        #   User.first.represent_as(:simple)
        #   User.limit(5).represent_as(:simple)
        #
        # @param [Symbol] mode
        # @param [Hash] opts
        #   (Symbol) paginate_with: paginator name, eg +:api+, +:admin+ etc.
        #   (Hash)   pagination: pagination parameters, eg +:page+, +:since_id+ or +:until_id+
        # @param [Hash] context Aadditional context informations
        #
        # @return [Object]
        def represent_as(mode, opts: nil, context: nil)
          representer.represent_as(self, mode, opts: opts, context: context)
        end
      end

      module InstanceMethods
        include SharedMethods

        # Fetch attribute value (works similar as Hash#fetch)
        #
        # @param [Symbol] attr
        # @param [Object] default
        #
        # @return [Object]
        def fetch(attr, default = nil)
          if respond_to?(attr)
            send(attr)
          elsif values.include?(attr)
            values[attr]
          else
            if !default.nil?
              default
            elsif block_given?
              yield(attr)
            else
              raise(MissingAttributeError, "Missing attribute #{attr}")
            end
          end
        end

        # Represent association in given mode
        #
        # @param [Symbol] association
        # @param [Symbol] mode
        #
        # @return [Object]
        def represent_association_as(association, mode)
          # get association type to differentiate if its singular or plural
          type = self.class.association_reflection(association)[:type]
          singular = (type == :many_to_one || type == :one_to_one)

          if associations.key?(association)
            # if association data are already loaded (cached)
            return unless (data = send(association))
            singular ? data.represent_as(mode) : data.map { |d| d.represent_as(mode) }
          else
            # if not, load its dataset and represent it
            repre = send("#{association}_dataset").represent_as(mode)
            singular ? repre[0] : repre
          end
        end
      end

      module DatasetMethods
        include SharedMethods

        # Modify the dataset with the proc stored in the representer.
        #
        #   User.dataset.modify_with(:simple).all
        #
        # @param [Symbol] mode
        #
        # @return [Sequel::Dataset]
        def modify_with(mode)
          representer.modify_with(self, mode)
        end

        # Paginate a dataset and return a represented dataset.
        #
        # @param [Symbol] name
        # @param [Hash] pagination pagination parameters, eg +:page+, +:since_id+ or +:until_id+
        def paginate_with(name, pagination = nil)
          representer.paginate_with(self, name, pagination)
        end
      end
    end
  end
end
