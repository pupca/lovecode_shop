require 'securerandom'

class Random
  # Generates a random hexadecimal string of given length
  #
  # @param [Fixnum] length (default 128)
  #
  # @return [String]
  def self.hex(length = 128)
    SecureRandom.hex(length.to_i / 2)
  end

  # Generate a random string of given length
  # Consists of 0..9, a..z, A..Z
  #
  # @param [Fixnum] length (default 10)
  #
  # @return [String]
  def self.string(length = 10)
    chars = [*'0'..'9', *'a'..'z', *'A'..'Z']
    length.to_i.times.map { chars.sample }.join
  end
end
