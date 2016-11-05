# Selected ActiveSupport NillClass extensions
# Taken from:
#
#   https://github.com/rails/rails/blob/master/activesupport
class NilClass
  def to_param
    self
  end

  # +nil+ is blank:
  #
  #   nil.blank? # => true
  def blank?
    true
  end

  def to_bool
    false
  end

  # +nil+ is not duplicable:
  #
  #   nil.duplicable? # => false
  #   nil.dup         # => TypeError: can't dup NilClass
  def duplicable?
    false
  end
end
