# Selected ActiveSupport String extensions
# Taken from:
#
#   https://github.com/rails/rails/blob/master/activesupport
class String
  # Removes the module part from the expression in the string:
  #
  #   "ActiveRecord::CoreExtensions::String::Inflections".demodulize # => "Inflections"
  #   "Inflections".demodulize                                       # => "Inflections"
  #
  # See also +deconstantize+.
  def demodulize
    if (i = rindex('::'))
      self[(i + 2)..-1]
    else
      self
    end
  end

  # Removes the rightmost segment from the constant expression in the string:
  #
  #   "Net::HTTP".deconstantize   # => "Net"
  #   "::Net::HTTP".deconstantize # => "::Net"
  #   "String".deconstantize      # => ""
  #   "::String".deconstantize    # => ""
  #   "".deconstantize            # => ""
  #
  # See also +demodulize+.
  def deconstantize
    self[0...(rindex('::') || 0)] # implementation based on the one in facets' Module#spacename
  end

  # Converts strings to UpperCamelCase
  def camelize
    str = dup
    str = str.sub(/^[a-z\d]*/, &:capitalize)
    str.gsub!(%r{(?:_|(\/))([a-z\d]*)}i) do
      "#{Regexp.last_match(1)}#{Regexp.last_match(2).capitalize}"
    end
    str.gsub!('/'.freeze, '::'.freeze)
    str
  end

  # Underscore a class name with or without namespaces, modified self.
  #
  #   "ActiveSupport::CoreExtensions::OAuthToken".underscore!
  #   => "active_support_core_extensions_o_auth_token"
  def underscore!
    gsub!('::', '_')
    gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
    gsub!(/([a-z\d])([A-Z])/, '\1_\2')
    downcase!
  end

  # Underscore a class name with or without namespaces.
  #
  #   "ActiveSupport::CoreExtensions::OAuthToken".underscore!
  #   => "active_support_core_extensions_o_auth_token"
  def underscore
    dup.underscore!
  end

  # A string is blank if it's empty or contains whitespaces only:
  #
  #   ''.blank?                 # => true
  #   '   '.blank?              # => true
  #   ' something here '.blank? # => false
  def blank?
    self !~ /[^[:space:]]/
  end

  # Checkes if self is an email
  def email?
    return false if blank?
    match(/\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/).present?
  end

  # Convert string to boolean
  #
  # @param [Boolean] strict
  #   if true, then string must be a possitive boolean representation
  #
  # @return [Boolean]
  def to_bool(strict = true)
    return false if blank? || self =~ /(false|f|no|n|0)$/i

    if strict
      return true if self =~ /(true|t|yes|y|1)$/i
      raise ArgumentError, "invalid value for Boolean: \"#{self}\""
    else
      return true
    end
  end

  # Replace placeholders with variables.
  #
  #   '/admin/users/detail/:id'.template(id: 5) => '/admin/users/detail/5'
  #
  # @param [Hash] data
  #
  # @return [String]
  def template(data = {})
    str = dup

    data.each do |key, value|
      str.gsub!(":#{key}", value.to_s)
    end

    str
  end

  # Truncates a given text after a given length if text is longer than `length`:
  #
  #   'Once upon a time in a world far far away'.truncate(27)
  #   # => "Once upon a time in a wo..."
  #
  # Pass a string or regexp `:separator` to truncate +text+ at a natural break:
  #
  #   'Once upon a time in a world far far away'.truncate(27, separator: ' ')
  #   # => "Once upon a time in a..."
  #
  #   'Once upon a time in a world far far away'.truncate(27, separator: /\s/)
  #   # => "Once upon a time in a..."
  #
  # The last characters will be replaced with the `:omission` string (defaults to "...")
  # for a total length not exceeding `length`:
  #
  #   'And they found that many people were sleeping .'.truncate(25, omission: '... (continued)')
  #   # => "And they f... (continued)"
  def truncate(truncate_at, options = {})
    return dup unless length > truncate_at

    omission = options[:omission] || '...'
    length_with_room_for_omission = truncate_at - omission.length
    stop =
      if options[:separator]
        rindex(options[:separator], length_with_room_for_omission) || length_with_room_for_omission
      else
        length_with_room_for_omission
      end

    "#{self[0, stop]}#{omission}"
  end

  # Same as +indent+, except it indents the receiver in-place.
  #
  # Returns the indented string, or +nil+ if there was nothing to indent.
  def indent!(amount, indent_string = nil, indent_empty_lines = false)
    indent_string = indent_string || self[/^[ \t]/] || ' '
    re = indent_empty_lines ? /^/ : /^(?!$)/
    gsub!(re, indent_string * amount)
  end

  # Indents the lines in the receiver:
  #
  #   <<EOS.indent(2)
  #   def some_method
  #     some_code
  #   end
  #   EOS
  #   # =>
  #     def some_method
  #       some_code
  #     end
  #
  # The second argument, +indent_string+, specifies which indent string to
  # use. The default is +nil+, which tells the method to make a guess by
  # peeking at the first indented line, and fallback to a space if there is
  # none.
  #
  #   "  foo".indent(2)        # => "    foo"
  #   "foo\n\t\tbar".indent(2) # => "\t\tfoo\n\t\t\t\tbar"
  #   "foo".indent(2, "\t")    # => "\t\tfoo"
  #
  # While +indent_string+ is typically one space or tab, it may be any string.
  #
  # The third argument, +indent_empty_lines+, is a flag that says whether
  # empty lines should be indented. Default is false.
  #
  #   "foo\n\nbar".indent(2)            # => "  foo\n\n  bar"
  #   "foo\n\nbar".indent(2, nil, true) # => "  foo\n  \n  bar"
  #
  def indent(amount, indent_string = nil, indent_empty_lines = false)
    dup.tap { |d| d.indent!(amount, indent_string, indent_empty_lines) }
  end

  def heredoc(prefix = '|')
    gsub(/^\s*#{Regexp.quote(prefix)}/m, '')
  end

  def numeric?
    Float(self) != nil rescue false
  end
end
