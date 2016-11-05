# Selected ActiveSupport Symbol extensions
# Taken from:
#
#   https://github.com/rails/rails/blob/master/activesupport
class Symbol
  # Symbols are not duplicable:
  #
  #   :my_symbol.duplicable? # => false
  #   :my_symbol.dup         # => TypeError: can't dup Symbol
  def duplicable?
    false
  end
end
