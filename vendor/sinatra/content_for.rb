require_relative 'capture'

module Sinatra
  module ContentFor
    include Capture

    def content_for(key, &block)
      content_blocks[key.to_sym] << proc { capture(&block) }
    end

    def content_for?(key)
      content_blocks[key.to_sym].any?
    end

    def yield_content(key)
      content_blocks[key.to_sym].map(&:call).join
    end

    private

    def content_blocks
      @content_blocks ||= Hash.new { |h, k| h[k] = [] }
    end
  end
end
