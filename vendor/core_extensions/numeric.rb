# Selected ActiveSupport Numeric extensions
# Taken from:
#
#   https://github.com/rails/rails/blob/master/activesupport
class Numeric
  # No number is blank:
  #
  #   1.blank? # => false
  #   0.blank? # => false
  def blank?
    false
  end

  # Numbers are not duplicable:
  #
  #  3.duplicable? # => false
  #  3.dup         # => TypeError: can't dup Fixnum
  def duplicable?
    false
  end

  def valueless?
    zero?
  end
end
