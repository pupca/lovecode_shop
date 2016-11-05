module Sequel
  # The exception classed raised if there is an error parsing JSON.
  # This can be overridden to use an alternative json implementation.
  def self.json_parser_error_class
    MultiJson::ParseError
  end

  # Convert given object to json and return the result.
  # This can be overridden to use an alternative json implementation.
  def self.object_to_json(obj, *_args)
    MultiJson.dump obj
  end

  # Parse the string as JSON and return the result.
  # This can be overridden to use an alternative json implementation.
  def self.parse_json(json)
    MultiJson.load json, symbolize_keys: true
  end
end
