# Selected ActiveSupport FalseClass extensions
# Taken from:
#
#   https://github.com/rails/rails/blob/master/activesupport
class FalseClass
  def to_param
    self
  end

  # +false+ is blank:
  #
  #   false.blank? # => true
  def blank?
    true
  end

  # +false+ is not duplicable:
  #
  #   false.duplicable? # => false
  #   false.dup         # => TypeError: can't dup FalseClass
  def duplicable?
    false
  end
end
