# Selected ActiveSupport Method extensions
# Taken from:
#
#   https://github.com/rails/rails/blob/master/activesupport
class Method
  # Methods are not duplicable:
  #
  #  method(:puts).duplicable? # => false
  #  method(:puts).dup         # => TypeError: allocator undefined for Method
  def duplicable?
    false
  end
end
