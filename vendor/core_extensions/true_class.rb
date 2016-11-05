# Selected ActiveSupport TrueClass extensions
# Taken from:
#
#   https://github.com/rails/rails/blob/master/activesupport
class TrueClass
  def to_param
    self
  end

  # +true+ is not blank:
  #
  #   true.blank? # => false
  def blank?
    false
  end

  # +true+ is not duplicable:
  #
  #   true.duplicable? # => false
  #   true.dup         # => TypeError: can't dup TrueClass
  def duplicable?
    false
  end
end
