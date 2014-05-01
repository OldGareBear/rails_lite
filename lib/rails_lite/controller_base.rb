require 'erb'
require_relative 'params'
require_relative 'session'
require 'active_support/inflector'

class ControllerBase
  attr_reader :params, :req, :res

  def initialize(req, res, route_params = {})
    @req = req
    @res = res

    @already_built_response = false

    @params = Params.new(req, route_params)
  end

  def session
    @session ||= Session.new(@req)
  end

  def already_built_response?
    @already_built_response
  end

  def redirect_to(url)
    raise 'double render error' if already_built_response?

    @res.status = 302
    @res.header['location'] = url
    session.store_session(@res)

    @already_built_response = true
    nil
  end

  def render_content(content, type)
    raise 'double render error' if already_built_response?

    @res.body = content
    @res.content_type = type
    session.store_session(@res)

    @already_built_response = true
    nil
  end

  def render(template_name)
    template_file_name = "#{template_name}.html.erb"
    template_path =
      File.join('views', self.class.name.underscore, template_file_name)
    content = ERB.new(File.read(template_path)).result(binding)

    render_content(content, 'text/html')
  end

  def invoke_action(name)
    send(name)
    render(name) unless already_built_response?

    nil
  end
end
