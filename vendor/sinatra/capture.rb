module Sinatra
  #
  # = Sinatra::Capture
  #
  # Extension that enables blocks inside other extensions.
  # It currently works for erb, slim and haml.
  # Enables mixing of different template languages.
  #
  # Example:
  #
  #    # in hello_world.erb
  #
  #    Say
  #    <% a = capture do %>World<% end %>
  #    Hello <%= a %>!
  #
  #    # in hello_world.slim
  #
  #    | Say
  #    - a = capture do
  #      | World
  #    |  Hello #{a}!
  #
  #    # in hello_world.haml
  #
  #    Say
  #    - a = capture do
  #      World
  #      Hello #{a.strip}!
  #
  #
  # You can also use nested blocks.
  #
  # Example
  #
  #     # in hello_world.erb
  #
  #     Say
  #     <% a = capture do %>
  #       <% b = capture do %>World<% end %>
  #         <%= b %>!
  #     <% end %>
  #     Hello <%= a.strip %>
  #
  #
  # The main advantage of capture is mixing of different template engines.
  #
  # Example
  #
  #    # in mix_me_up.slim
  #
  #    - two = capture do
  #      - erb "<%= 1 + 1 %>"
  #    | 1 + 1 = #{two}
  #
  # == Usage
  #
  # === Classic Application
  #
  # In a classic application simply require the helpers, and start using them:
  #
  #     require "sinatra"
  #     require "sinatra/capture"
  #
  #     # The rest of your classic application code goes here...
  #
  # === Modular Application
  #
  # In a modular application you need to require the helpers, and then tell
  # the application you will use them:
  #
  #     require "sinatra/base"
  #     require "sinatra/capture"
  #
  #     class MyApp < Sinatra::Base
  #       helpers Sinatra::Capture
  #
  #       # The rest of your modular application code goes here...
  #     end
  #
  module Capture
    def capture(&block)
      buf_before = @_out_buf
      @_out_buf = ''

      yield
      result = eval('@_out_buf', block.binding)

      @_out_buf = buf_before

      result
    end
  end
end
