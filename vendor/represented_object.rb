# This is a tiny wrapper class around a Hash object.
# It's aim is to provide multiple access interfaces (getter and setter).
# It supports:
#
# * Method-like access with +.+,
# * Array-like access with +[]+,
# * Set multiple attributes with +set(hash)+.
#
# It is optimized for minimum memory and maximum speed therefore
# the implementation is done via method_missing and direct hash access.
# Attribute accessors proved to eat around five times more memory and
# are slower.
class RepresentedObject
  # Attributes and their values.
  #
  # @return [Hash]
  attr_reader :values

  # Set attributes in initializer.
  #
  #   o = RepresentedObject.new(name: 'John', age: 45)
  #   o.values # => { name: "Joe", age: 45 }
  #
  # @param [Hash] attributes
  def initialize(attributes = {})
    @values = {}
    set(attributes)
  end

  # Set all attributes at once.
  #
  #   o = RepresentedObject.new
  #   o.set(name: 'John', age: 45)
  #   o.name # => "John"
  #   o.age  # => 45
  #   o.values # => { name: "Joe", age: 45 }
  #
  # @param [Hash] attributes
  #
  # @return [RepresentedObject]
  def set(attributes)
    attributes.each do |attribute, value|
      @values[attribute] = value
    end

    self
  end

  # Serialize this for JSON engine.
  #
  # @return [Hash]
  def as_json
    @values
  end

  # Serialize this for JSON string.
  # The +json+ gem does not use +as_json+. :-/
  #
  # @return [String]
  def to_json(*_args)
    MultiJson.dump(as_json)
  end

  # Array-like getter.
  #
  #   o = RepresentedObject
  #   o[:name] = "John"
  #   o[:name] # => "John"
  #   o[:age]  # => nil
  #
  # @param [Symbol, String] attribute
  def [](attribute)
    @values[attribute]
  end

  # Array-like setter.
  #
  #   o = RepresentedObject
  #   o[:name] = "John"
  #   o[:name] # => "John"
  #
  # @param [Symbol, String] attribute
  def []=(attribute, value)
    @values[attribute] = value
  end

  # Method-like getter / setter.
  #
  #   o = RepresentedObject
  #   o.name = "John"
  #   o.name # => "John"
  #   o.age  # => NoMethodError
  #
  # @param [Symbol] meth Eg +:name+, +:name=+
  def method_missing(meth, *args)
    case args.size
    when 0
      # Attribute getter
      #
      # If meth is in @values.keys, then it is a getter so simply return it
      #
      # Example data:
      #   meth == :name
      #   args == []

      # Unrecognized attribute
      super unless @values.keys.include?(meth)

      # Get the value
      @values[meth]
    when 1
      # Attribute setter
      #
      # Check if meth ends with "=" which means it is a setter.
      # Otherwise raise an error.
      #
      # Example data:
      #   meth == :name=
      #   args == ["John"]

      meth_string = meth.to_s

      # Must end with a "="
      super unless meth_string[-1] == '='

      # "name=" -> :name
      attribute = meth_string.chop.to_sym

      # Set the value, can be unrecognized
      @values[attribute] = args.first
    else # Everything else is an error
      super
    end
  end
end
