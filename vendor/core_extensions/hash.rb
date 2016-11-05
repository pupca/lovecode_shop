# Selected ActiveSupport Hash extensions
# Taken from:
#
#   https://github.com/rails/rails/blob/master/activesupport
class Hash
  # Return a new hash with all keys converted using the block operation.
  #
  #  hash = { name: 'Rob', age: '28' }
  #
  #  hash.transform_keys{ |key| key.to_s.upcase }
  #  # => { "NAME" => "Rob", "AGE" => "28" }
  def transform_keys
    result = {}
    each_key do |key|
      result[yield(key)] = self[key]
    end
    result
  end

  # Destructively convert all keys using the block operations.
  # Same as transform_keys but modifies +self+.
  def transform_keys!
    keys.each do |key|
      self[yield(key)] = delete(key)
    end
    self
  end

  # Return a new hash with all keys converted to strings.
  #
  #   hash = { name: 'Rob', age: '28' }
  #
  #   hash.stringify_keys
  #   #=> { "name" => "Rob", "age" => "28" }
  def stringify_keys
    transform_keys(&:to_s)
  end

  # Destructively convert all keys to strings. Same as
  # +stringify_keys+, but modifies +self+.
  def stringify_keys!
    transform_keys!(&:to_s)
  end

  # Return a new hash with all keys converted to symbols, as long as
  # they respond to +to_sym+.
  #
  #   hash = { 'name' => 'Rob', 'age' => '28' }
  #
  #   hash.symbolize_keys
  #   #=> { name: "Rob", age: "28" }
  def symbolize_keys
    transform_keys(&:to_sym)
  end

  # Destructively convert all keys to symbols, as long as they respond
  # to +to_sym+. Same as +symbolize_keys+, but modifies +self+.
  def symbolize_keys!
    transform_keys!(&:to_sym)
  end

  # Return a new hash with all keys converted by the block operation.
  # This includes the keys from the root hash and from all
  # nested hashes.
  #
  #  hash = { person: { name: 'Rob', age: '28' } }
  #
  #  hash.deep_transform_keys{ |key| key.to_s.upcase }
  #  # => { "PERSON" => { "NAME" => "Rob", "AGE" => "28" } }
  def deep_transform_keys(&block)
    result = {}
    each do |key, value|
      result[yield(key)] = value.is_a?(Hash) ? value.deep_transform_keys(&block) : value
    end
    result
  end

  # Destructively convert all keys by using the block operation.
  # This includes the keys from the root hash and from all
  # nested hashes.
  def deep_transform_keys!(&block)
    keys.each do |key|
      value = delete(key)
      self[yield(key)] = value.is_a?(Hash) ? value.deep_transform_keys!(&block) : value
    end
    self
  end

  # Return a new hash with all keys converted to strings.
  # This includes the keys from the root hash and from all
  # nested hashes.
  #
  #   hash = { person: { name: 'Rob', age: '28' } }
  #
  #   hash.deep_stringify_keys
  #   # => { "person" => { "name" => "Rob", "age" => "28" } }
  def deep_stringify_keys
    deep_transform_keys(&:to_s)
  end

  # Destructively convert all keys to strings.
  # This includes the keys from the root hash and from all
  # nested hashes.
  def deep_stringify_keys!
    deep_transform_keys!(&:to_s)
  end

  # Return a new hash with all keys converted to symbols, as long as
  # they respond to +to_sym+. This includes the keys from the root hash
  # and from all nested hashes.
  #
  #   hash = { 'person' => { 'name' => 'Rob', 'age' => '28' } }
  #
  #   hash.deep_symbolize_keys
  #   # => { person: { name: "Rob", age: "28" } }
  def deep_symbolize_keys
    deep_transform_keys(&:to_sym)
  end

  # Destructively convert all keys to symbols, as long as they respond
  # to +to_sym+. This includes the keys from the root hash and from all
  # nested hashes.
  def deep_symbolize_keys!
    deep_transform_keys!(&:to_sym)
  end

  # Returns a new hash with +self+ and +other_hash+ merged recursively.
  #
  #   h1 = { a: true, b: { c: [1, 2, 3] } }
  #   h2 = { a: false, b: { x: [3, 4, 5] } }
  #
  #   h1.deep_merge(h2) #=> { a: false, b: { c: [1, 2, 3], x: [3, 4, 5] } }
  #
  # Like with Hash#merge in the standard library, a block can be provided
  # to merge values:
  #
  #   h1 = { a: 100, b: 200, c: { c1: 100 } }
  #   h2 = { b: 250, c: { c1: 200 } }
  #   h1.deep_merge(h2) { |key, this_val, other_val| this_val + other_val }
  #   # => { a: 100, b: 450, c: { c1: 300 } }
  def deep_merge(other_hash, &block)
    dup.deep_merge!(other_hash, &block)
  end

  # Same as +deep_merge+, but modifies +self+.
  def deep_merge!(other_hash, &block)
    other_hash.each_pair do |k, v|
      tv = self[k]
      self[k] = if tv.is_a?(Hash) && v.is_a?(Hash)
                  tv.deep_merge(v, &block)
                else
                  block && tv ? yield(k, tv, v) : v
                end
    end
    self
  end

  # Slice a hash to include only the given keys. This is useful for
  # limiting an options hash to valid keys before passing to a method:
  #
  #   def search(criteria = {})
  #     criteria.assert_valid_keys(:mass, :velocity, :time)
  #   end
  #
  #   search(options.slice(:mass, :velocity, :time))
  #
  # If you have an array of keys you want to limit to, you should splat them:
  #
  #   valid_keys = [:mass, :velocity, :time]
  #   search(options.slice(*valid_keys))
  def slice(*keys)
    keys.map! { |key| convert_key(key) } if respond_to?(:convert_key, true)
    keys.each_with_object(self.class.new) { |k, hash| hash[k] = self[k] if key?(k) }
  end

  # Replaces the hash with only the given keys.
  # Returns a hash containing the removed key/value pairs.
  #
  #   { a: 1, b: 2, c: 3, d: 4 }.slice!(:a, :b)
  #   # => {:c=>3, :d=>4}
  def slice!(*keys)
    keys.map! { |key| convert_key(key) } if respond_to?(:convert_key, true)
    omit = slice(*self.keys - keys)
    hash = slice(*keys)
    replace(hash)
    omit
  end

  # Return a hash that includes everything but the given keys. This is useful for
  # limiting a set of parameters to everything but a few known toggles:
  #
  #   @person.update(params[:person].except(:admin))
  def except(*keys)
    dup.except!(*keys)
  end

  # Replaces the hash without the given keys.
  def except!(*keys)
    keys.each { |key| delete(key) }
    self
  end

  # Renames specified key.
  def rename_key(old_key, new_key)
    self[new_key] = delete(old_key) if key?(old_key)
  end

  def numerize(*keys)
    dup.numerize!(*keys)
  end

  def numerize!(*keys)
    keys.each { |key| self[key] = self[key].to_i }
    self
  end

  # Returns a string representation of the receiver suitable for use as a URL
  # query string:
  #
  #   {:name => 'David', :nationality => 'Danish'}.to_param
  #   # => "name=David&nationality=Danish"
  #
  # An optional namespace can be passed to enclose the param names:
  #
  #   {:name => 'David', :nationality => 'Danish'}.to_param('user')
  #   # => "user[name]=David&user[nationality]=Danish"
  #
  # The string pairs "key=value" that conform the query string
  # are sorted lexicographically in ascending order.
  #
  # This method is also aliased as +to_query+.
  def to_param(namespace = nil)
    map do |key, value|
      value.to_query(namespace ? "#{namespace}[#{key}]" : key)
    end.sort * '&'
  end

  def to_html_attributes
    map { |key, value| %(#{key}="#{value}") }.join(' ')
  end

  # A hash is blank if it's empty:
  #
  #   {}.blank?                # => true
  #   { key: 'value' }.blank?  # => false
  alias blank? empty?

  alias to_query to_param

  def with_defaults(defaults = {})
    defaults.merge(self)
  end

  def self.with_keys(*keys)
    h = {}
    keys.each { |key| h[key] = nil }
    h
  end

  def first_value(*keys)
    candidates = keys & self.keys
    raise(KeyError, "None of the keys found: #{keys}") if candidates.empty?
    self[candidates.first]
  end

  # Returns a deep copy of hash.
  #
  #   hash = { a: { b: 'b' } }
  #   dup  = hash.deep_dup
  #   dup[:a][:c] = 'c'
  #
  #   hash[:a][:c] # => nil
  #   dup[:a][:c]  # => "c"
  def deep_dup
    each_with_object(dup) do |(key, value), hash|
      hash.delete(key)
      hash[key.deep_dup] = value.deep_dup
    end
  end

  def valueless?
    values.valueless?
  end
end
