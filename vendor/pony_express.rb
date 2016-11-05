require 'tilt/erubis'

class PonyExpress
  TEMPLATES_DIR = 'views/emails'

  class << self
    def mail(opts = {})
      mail_opts = opts.slice(:to, :subject, :attachments)
      mail_opts.merge!(
        body: render_template("#{opts[:template]}", opts[:template_data])
      )

      Pony.mail(mail_opts)
    end

    private

    def template_path(template)
      "#{TEMPLATES_DIR}/#{template}.erb"
    end

    def render_template(template, data = {})
      Tilt::ErubisTemplate.new(template_path(template)).render(nil, data)
    end
  end
end
