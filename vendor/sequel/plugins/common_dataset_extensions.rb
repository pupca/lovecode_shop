module Sequel
  module Plugins
    module CommonDatasetExtensions
      module DatasetMethods
        # Return hash of hashes representing dataset model
        #
        # @param [Symbol] key: column representing identity key
        # @param [Array<Symbol>|Symbol] values: columns contained in representation hash
        #
        # @return [Hash]
        def select_hash_as_hash(key, values)
          values = Array(values)

          hash = select_hash(key, values)
          hash.each do |k, v|
            hash[k] = Hash[values.zip(v)]
          end
          hash
        end

        # Return array of hashes representing dataset model
        #
        # @param [Array<Symbol>|Symbol] values: columns contained in representation hash
        #
        # @return [Array]
        def select_map_as_hash(values)
          values = Array(values)

          select_map(values).map! { |v| Hash[values.zip(v)] }
        end
      end
    end
  end
end
