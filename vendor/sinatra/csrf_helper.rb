module Sinatra
  module CSRFHelper
    def csrf_tag
      %(<input type="hidden" name="authenticity_token" value="#{session[:csrf]}">)
    end
  end
end
