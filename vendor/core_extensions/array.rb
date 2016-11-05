# Selected ActiveSupport Array extensions
# Taken from:
#
#   https://github.com/rails/rails/blob/master/activesupport
class Array
  # File activesupport/lib/active_support/core_ext/enumerable.rb, line 94
  def index_by
    return to_enum :index_by unless block_given?
    Hash[map { |elem| [yield(elem), elem] }]
  end

  # Calls <tt>to_param</tt> on all its elements and joins the result with
  # slashes. This is used by <tt>url_for</tt> in Action Pack.
  def to_param
    map(&:to_param).join '/'
  end

  # Converts an array into a string suitable for use as a URL query string,
  # using the given +key+ as the param name.
  #
  #   ['Rails', 'coding'].to_query('hobbies') # => "hobbies%5B%5D=Rails&hobbies%5B%5D=coding"
  def to_query(key)
    prefix = "#{key}[]"
    map { |value| value.to_query(prefix) }.join '&'
  end

  # An array is blank if it's empty:
  #
  #   [].blank?      # => true
  #   [1,2,3].blank? # => false
  alias blank? empty?

  # Returns a deep copy of array.
  #
  #   array = [1, [2, 3]]
  #   dup   = array.deep_dup
  #   dup[1][2] = 4
  #
  #   array[1][2] # => nil
  #   dup[1][2]   # => 4
  def deep_dup
    map(&:deep_dup)
  end

  def valueless?
    find { |i| !i.valueless? } ? false : true
  end
end
