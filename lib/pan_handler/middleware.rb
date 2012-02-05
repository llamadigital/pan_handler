class PanHandler

  class Middleware

    def initialize(app, options = {}, conditions = {})
      @app        = app
      @options    = options
      @conditions = conditions
    end

    def call(env)
      @request    = Rack::Request.new(env)
      @render_odt = false

      set_request_to_render_as_odt(env) if render_as_odt?
      status, headers, response = @app.call(env)

      if rendering_odt? && headers['Content-Type'] =~ /text\/html|application\/xhtml\+xml/
        body = response.respond_to?(:body) ? response.body : response.join
        body = body.join if body.is_a?(Array)
        body = PanHandler.new(translate_paths(body, env), @options).to_odt
        response = [body]

        # Do not cache ODTs
        headers.delete('ETag')
        headers.delete('Cache-Control')

        headers["Content-Length"] = (body.respond_to?(:bytesize) ? body.bytesize : body.size).to_s
        headers["Content-Type"]   = "application/vnd.oasis.opendocument.text"
      end

      [status, headers, response]
    end

    private

    # Change relative paths to absolute
    def translate_paths(body, env)
      # Host with protocol
      root = PanHandler.configuration.root_url || "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}/"
      body.gsub(/(href|src)=(['"])\/([^\"']*|[^"']*)['"]/, '\1=\2' + root + '\3\2')
    end

    def rendering_odt?
      @render_odt
    end

    def render_as_odt?
      request_path_is_odt = @request.path.match(%r{\.odt$})

      if request_path_is_odt && @conditions[:only]
        rules = [@conditions[:only]].flatten
        rules.any? do |pattern|
          if pattern.is_a?(Regexp)
            @request.path =~ pattern
          else
            @request.path[0, pattern.length] == pattern
          end
        end
      elsif request_path_is_odt && @conditions[:except]
        rules = [@conditions[:except]].flatten
        rules.map do |pattern|
          if pattern.is_a?(Regexp)
            return false if @request.path =~ pattern
          else
            return false if @request.path[0, pattern.length] == pattern
          end
        end

        return true
      else
        request_path_is_odt
      end
    end

    def set_request_to_render_as_odt(env)
      @render_odt = true
      path = @request.path.sub(%r{\.odt$}, '')
      %w[PATH_INFO REQUEST_URI].each { |e| env[e] = path }
      env['HTTP_ACCEPT'] = concat(env['HTTP_ACCEPT'], Rack::Mime.mime_type('.html'))
      env["Rack-Middleware-PanHandler"] = "true"
    end

    def concat(accepts, type)
      (accepts || '').split(',').unshift(type).compact.join(',')
    end

  end
end
