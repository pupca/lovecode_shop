# Selected ActiveSupport Array extensions
# Taken from:
#
#   https://github.com/rails/rails/blob/master/activesupport
module Enumerable
  # The negative of the <tt>Enumerable#include?</tt>. Returns +true+ if the
  # collection does not include the object.
  def exclude?(object)
    !include?(object)
  end
end
