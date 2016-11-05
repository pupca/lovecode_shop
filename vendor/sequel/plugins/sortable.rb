module Sequel
  module Plugins
    module Sortable
      module DatasetMethods
        # Sort dataset. Usage:
        #
        #   # sort directly
        #   params[:sort] = 'created_at_desc'
        #
        #   # sort with custom callback 'sort_by_user_name_asc'
        #   params[:sort] = 'method__user_name_asc'
        #
        #   SomeModel.where(...).sort(params[:sort])
        #
        # The two sort strings (or symbols) are of those formats:
        #
        #   # sort directly by order()
        #   "#{field}_#{order}"
        #
        #   # call back a dataset method "sort_by_#{field}_#{order}", don't sort directly
        #   "method__#{field}_#{order}"
        #
        # The second format is useful for sorting by associated fields, so you can define
        # your own method and let it do the sorting.
        #
        # @param sort_string         [String|Symbol]
        # @param default_sort_string [String|Symbol]
        # @return ordered dataset
        def sort(sort_string, default_sort_string = nil)
          sort_string = default_sort_string if sort_string.blank? && default_sort_string.present?
          sort_string = sort_string.to_s
          return self if sort_string.blank?

          # Call a callback and return its return.
          if sort_string.match(/^method__/)
            return compose_and_call_sort_method(sort_string)
          end

          # In case we got something like 'created_at_desc'
          field_part, order_part = extract_parts(sort_string)
          qualified_field = Sequel.qualify(model.table_name, field_part)

          case order_part
          when :desc
            order(Sequel.desc(qualified_field))
          else
            order(Sequel.asc(qualified_field))
          end
        end

        protected

        # If a sort string starts with "method__", e.g. `:method__name_asc`
        # It will look for those two dataset methods `order_by_name_asc` and `sort_by_name_asc`.
        #
        # @param [String] sort_string
        #
        # @return [Sequel::Dataset]
        def compose_and_call_sort_method(sort_string)
          clean_sort_string = sort_string.gsub(/^method__/, '')
          sort_method_name  = "sort_by_#{clean_sort_string}"
          order_method_name = "order_by_#{clean_sort_string}"

          if respond_to?(order_method_name)
            return send(order_method_name)
          else
            return send(sort_method_name)
          end
        end

        # Takes a string, ie 'created_at_desc' and returns [ :created_at, :desc ].
        def extract_parts(sort_string)
          *field_parts, order_part = sort_string.split('_')
          field_part = field_parts.join('_').to_sym
          order_part = order_part.to_sym

          [field_part, order_part]
        end
      end
    end
  end
end
