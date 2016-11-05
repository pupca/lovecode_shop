class Time
  # Create Time object from given object
  #
  #     Time.from(Time.now)                    # => 2014-07-03 11:52:29 +0200
  #     Time.from(Date.today)                  # => 2014-07-03 00:00:00 +0200
  #     Time.from(DateTime.now)                # => 2014-07-03 11:53:50 +0200
  #     Time.from('1404381277')                # => 2014-07-03 11:54:37 +0200
  #     Time.from('5.days.from_now')           # => 2014-07-08 12:04:14 +0200
  #     Time.from('2.minutes.ago')             # => 2014-07-03 12:02:50 +0200
  #     Time.from('2014-07-08 12:04:14 +0200') # => 2014-07-08 12:04:14 +0200
  #     Time.from(1404381277)                  # => 2014-07-03 11:54:37 +0200
  #
  # @param [Time|Date|DateTime|String|Fixnum] obj
  #
  # @return [Time]
  def self.from(obj)
    case obj
    when Time
      obj
    when Date, DateTime
      obj.to_time
    when String
      from_string(obj)
    when Fixnum, Float
      at(obj)
    else
      raise ArgumentError, "Object of type #{obj.class} can't be parsed as valid Time"
    end
  end

  # Create Time object from given string
  #
  #     Time.from('1404381277')                # => 2014-07-03 11:54:37 +0200
  #     Time.from('5.days.from_now')           # => 2014-07-08 12:04:14 +0200
  #     Time.from('2.minutes.ago')             # => 2014-07-03 12:02:50 +0200
  #     Time.from('2014-07-08 12:04:14 +0200') # => 2014-07-08 12:04:14 +0200
  #
  # @param [String] str
  #
  # @return [Time]
  def self.from_string(str)
    if str =~ /^[-+]?[0-9]*\.?[0-9]+$/
      at($LAST_MATCH_INFO[0].to_f)
    elsif str =~ /^(\d+)\.(second|seconds|minute|minutes|day|days)\.(from_now|ago)$/
      $LAST_MATCH_INFO[1].to_i.send($LAST_MATCH_INFO[2].to_sym).send($LAST_MATCH_INFO[3].to_sym)
    else
      parse(str)
    end
  end

  # Convert current time to stamp
  #
  #     Time.now.to_stamp   # => "1405376196.805000"
  #
  # @return [String]
  def to_stamp
    "#{tv_sec}.#{tv_usec}"
  end

  # Create time object from its stamp representation
  #
  #     Time.from_stamp('1405376196.805000')  # => 2014-07-15 00:16:36 +0200
  #
  # @param [String] stamp
  #
  # @return [Time]
  def self.from_stamp(stamp)
    sec, usec = stamp.to_s.split('.')
    at(sec.to_i, usec.to_i)
  end

  def distance_in_words(to_time)
    from_time = self
    from_time, to_time = to_time, from_time if from_time > to_time

    distance_in_minutes = ((to_time - from_time) / 60.0).round
    distance_in_seconds = (to_time - from_time).round

    case distance_in_minutes
    when 0..1
      case distance_in_seconds
      when 0..4   then 'less than 5 seconds'
      when 5..9   then 'less than 10 seconds'
      when 10..19 then 'less than 20 seconds'
      when 20..39 then 'half a minute'
      when 40..59 then 'less than a minute'
      else             '1 minute'
      end
    when 2...45
      amount = distance_in_minutes
      "#{amount} minutes"
    when 45...90
      'about 1 hour'
    when 90...1_440
      amount = (distance_in_minutes / 60.0).round
      "about #{amount} hours"
    when 1_440...2_520
      '1 day'
    when 2_520...43_200
      amount = (distance_in_minutes / 1_440.0).round
      "#{amount} days"
    when 43_200...86_400
      amount = (distance_in_minutes / 43_200.0).round
      "about #{amount} month#{'s' if amount > 1}"
    when 86_400...525_600
      amount = (distance_in_minutes / 43_200.0).round
      "#{amount} months"
    else
      remainder = distance_in_minutes % 525_600
      distance_in_years = distance_in_minutes.div(525_600)

      if remainder < 131_400
        amount = distance_in_years
        "about #{amount} year#{'s' if amount > 1}"
      elsif remainder < 394_200
        amount = distance_in_years
        "over #{amount} year#{'s' if amount > 1}"
      else
        amount = distance_in_years + 1
        "almost #{amount} year#{'s' if amount > 1}"
      end
    end
  end
end
