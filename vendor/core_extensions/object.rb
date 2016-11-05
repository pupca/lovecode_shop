# Selected ActiveSupport Object extensions
# Taken from:
#
#   https://github.com/rails/rails/blob/master/activesupport
class Object
  # Converts an object into a string suitable for use as a URL query string, using the given
  # <tt>key</tt> as the param name.
  #
  # Note: This method is defined as a default implementation for all Objects for Hash#to_query to
  # work.
  def to_query(key)
    require 'cgi' unless defined?(CGI) && defined?(CGI.escape)
    "#{CGI.escape(key.to_param)}=#{CGI.escape(to_param.to_s)}"
  end

  # Alias of <tt>to_s</tt>.
  def to_param
    to_s
  end

  # An object is blank if it's false, empty, or a whitespace string.
  # For example, '', '   ', +nil+, [], and {} are all blank.
  #
  # This simplifies:
  #
  #   if address.nil? || address.empty?
  #
  # ...to:
  #
  #   if address.blank?
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  # An object is present if it's not <tt>blank?</tt>.
  def present?
    !blank?
  end

  # Boolean representation of object
  # Simply if present? then true
  #
  # @return [Boolean]
  def to_bool
    present?
  end

  # Can you safely dup this object?
  #
  # False for +nil+, +false+, +true+, symbol, number, method objects;
  # true otherwise.
  def duplicable?
    true
  end

  # Returns a deep copy of object if it's duplicable. If it's
  # not duplicable, returns +self+.
  #
  #   object = Object.new
  #   dup    = object.deep_dup
  #   dup.instance_variable_set(:@a, 1)
  #
  #   object.instance_variable_defined?(:@a) # => false
  #   dup.instance_variable_defined?(:@a)    # => true
  def deep_dup
    duplicable? ? dup : self
  end

  def valueless?
    blank?
  end
end
