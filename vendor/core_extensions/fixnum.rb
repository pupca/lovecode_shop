# Some time-related helpers.
class Fixnum
  # Go back in time from right now.
  #
  #   5.days.ago => 2014-06-12 13:21:38 +0200
  #
  # @return [Time]
  def ago
    before(Time.now)
  end

  # Go forward in time from right now.
  #
  #   5.days.from_now => 2014-06-22 13:21:42 +0200
  #
  # @return [Time]
  def from_now
    after(Time.now)
  end

  # Go back in time from some other time.
  #
  #   some_time = Time.new(2014, 6, 17)
  #   5.days.before(some_time) => 2014-06-12 00:00:00 +0200
  #
  # @param time [Time]
  # @return     [Time]
  def before(time)
    time - self
  end

  # Go forward in time from some other time.
  #
  #   some_time = Time.new(2014, 6, 17)
  #   5.days.after(some_time) => 2014-06-22 00:00:00 +0200
  #
  # @param time [Time]
  # @return     [Time]
  def after(time)
    time + self
  end

  # Seconds
  #
  # @return [Fixnum]
  def seconds
    self
  end
  alias second seconds

  # Minutes as seconds.
  #
  # @return [Fixnum]
  def minutes
    self * 60
  end
  alias minute minutes

  # Hours as seconds
  #
  # @return [Fixnum]
  def hours
    self * 3_600
  end
  alias hour hours

  # Days as seconds
  #
  # @return [Fixnum]
  def days
    self * 86_400
  end
  alias day days

  # Months as seconds
  #
  # @return [Fixnum]
  def months
    self * 2_592_000
  end
  alias month months

  # Years as seconds
  #
  # @return [Fixnum]
  def years
    self * 31_557_600
  end
  alias year years

  # Bytes
  #
  # @return [Fixnum]
  def bytes
    self
  end
  alias byte bytes

  # Kilobytes as bytes
  #
  # @return [Fixnum]
  def kilobytes
    self * 1_024
  end
  alias kilobyte kilobytes

  # Megabytes as bytes
  #
  # @return [Fixnum]
  def megabytes
    self * 1_048_576
  end
  alias megabyte megabytes

  # Gigabytes as bytes
  #
  # @return [Fixnum]
  def gigabytes
    self * 1_073_741_824
  end
  alias gigabyte gigabytes

  # Terabytes as bytes
  #
  # @return [Fixnum]
  def terabytes
    self * 1_099_511_627_776
  end
  alias terabyte terabytes

  def to_human_byte_size
    units = %w(B kB MB GB TB)

    bytes = self
    i = 0

    loop do
      break if bytes < 1024

      bytes /= 1024.0
      i += 1
    end

    bytes = bytes.round(1)
    bytes = bytes.tap { |b| break b.to_i == b ? b.to_i : b }

    "#{bytes} #{units[i]}"
  end
end
