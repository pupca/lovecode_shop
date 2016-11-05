class Class
  # Classes which are descendants of self
  #
  # @return [Array]
  def descendants
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end
end
