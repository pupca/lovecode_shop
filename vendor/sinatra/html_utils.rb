module Sinatra
  module HTMLUtils
    # Make HTML response with specified status code
    #
    # @param [String|Symbol] template
    #   If string, then rendered directly, if symbol, then like a view
    def html(template, opts = {})
      content_type :html

      if template.is_a?(String)
        body subject
      elsif template.is_a?(Symbol)
        opts[:views] ||= settings.views

        file = File.join(opts[:views], template.to_s)
        file = "#{file}.html" unless File.extname(file) == '.html'
        body File.read(file)
      else
        raise ArgumentError, 'Invalid template to render'
      end
    end
  end
end
