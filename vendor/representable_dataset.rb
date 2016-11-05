require_relative 'represented_object'

class RepresentableDataset
  # Raw dataset.
  #
  # @return [Sequel::Dataset]
  attr_reader :dataset

  # An array of +Sequel::Model+ or anything else mapped from +Sequel::Dataset+.
  #
  # @return [Array]
  attr_accessor :raw_items

  # Were the items loaded?
  #
  # @return [Bool]
  attr_accessor :loaded

  # Pagination hash for next page.
  #
  # @return [Hash]
  attr_accessor :next_page_params

  # Pagination hash for previous page.
  #
  # @return [Hash]
  attr_accessor :prev_page_params

  # Loop over the dataset items and put them in a special array
  # with a few extra methods.
  #
  # @param [Array<Sequel::Dataset>] dataset
  def initialize(dataset)
    self.dataset = dataset
    self.loaded  = false
  end

  # Yield the current dataset, if dataset was return, load all items,
  # otherwise store them unchanged.
  #
  #   rds.load # => Array
  #
  #   rds.load do |ds|
  #     ds.limit(5) # => Sequel::Dataset
  #   end # => Array
  #
  #   rds.load do |ds|
  #     ds.limit(5).select_map(:name) # => Array
  #   end # => Array
  #
  # @yieldparam [Sequel::Dataset] Dataset before modification
  # @yieldreturn [Sequel::Dataset, Array] New specific dataset or an array
  #
  # @return [Array]
  def load
    if block_given?
      dataset_or_array = yield(dataset)
      self.raw_items   = if dataset_or_array.is_a?(Sequel::Dataset)
                           dataset_or_array.all
                         else
                           dataset_or_array
                         end
    else
      self.raw_items = dataset.all
    end

    self.loaded = true

    raw_items
  end

  # Array of loaded items.
  #
  # @return [Array]
  def items
    load unless loaded
    raw_items
  end

  # Dataset setter.
  # Value must be a Sequel::Dataset, otherwise raises an error.
  #
  # @param [Sequel::Dataset] value
  def dataset=(value)
    raise(TypeError, "Expected Sequel::Dataset, got #{value.class}") unless
      value.is_a?(Sequel::Dataset)

    @dataset = value
  end

  # Is there a next page?
  #
  # @return [Bool]
  def next_page?
    next_page_params.present?
  end

  # Is there a previous page?
  #
  # @return [Bool]
  def prev_page?
    prev_page_params.present?
  end

  # Simple pagination hash contiaining both next and prev page params hash.
  #
  # @return [Hash]
  def pagination
    {}.tap do |h|
      h[:next_page_params] = next_page_params if next_page?
      h[:prev_page_params] = prev_page_params if prev_page?
    end
  end

  # Serialize this for JSON engine.
  #
  # @return [Array]
  def as_json
    items
  end

  # Serialize this for JSON string.
  # The +json+ gem does not use +as_json+. :-/
  #
  # @return [String]
  def to_json(*_args)
    MultiJson.dump(items)
  end

  ####################
  # Array-like methods
  ####################

  # Returns the number of elements in self.items. May be zero.
  #
  # @return [Fixnum]
  def length
    items.length
  end

  alias size length

  # Returns the number of elements.
  #
  # If an argument is given, counts the number of elements which equal obj using
  # ==.
  #
  # If a block is given, counts the number of elements for which the block
  # returns a true value.
  #
  # @return [Fixnum]
  def count(*args, &block)
    items.count(*args, &block)
  end

  # Returns true if self.items contains no elements.
  #
  # @return [Bool]
  def empty?
    items.empty?
  end

  # Returns the first element, or the first n elements, of the array. If the
  # array is empty, the first form returns nil, and the second form returns an
  # empty array. See also #last for the opposite effect.
  def first(*args)
    items.first(*args)
  end

  # Returns the last element(s) of self. If the array is empty, the first form
  # returns nil.
  def last(*args)
    items.last(*args)
  end

  # Return array of items.
  #
  # @return [Array]
  def to_a
    items
  end

  #########################
  # Enumerable-like methods
  #########################

  # Calls the given block once for each element in self.items, passing that
  # element as a parameter.
  #
  # An Enumerator is returned if no block is given.
  #
  # @return [Array, Enumerator]
  def each(&block)
    items.each(&block)
  end

  # Invokes the given block once for each element of self.
  # Creates a new array containing the values returned by the block.
  # See also Enumerable#collect.
  # If no block is given, an Enumerator is returned instead.
  #
  # @return [Array, Enumerator]
  def map(&block)
    items.map(&block)
  end

  # Invokes the given block once for each element of self, replacing the element
  # with the value returned by the block.
  #
  # See also Enumerable#collect.
  #
  # If no block is given, an Enumerator is returned instead.
  def map!(&block)
    items.map!(&block)
  end

  # Element Reference, see Array#[].
  def [](*args)
    items[*args]
  end
end
