module Sequel
  module Plugins
    module SelectPrepend
      module DatasetMethods
        def select_prepend(*args)
          selected = opts[:select]

          ds = select(*args)

          if selected.present? && (selected -= ['*']).present?
            ds = ds.select_append(*selected)
          end

          ds
        end
      end
    end
  end
end
