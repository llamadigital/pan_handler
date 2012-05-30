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
      @render_docx = false

      if render_as_odt?
        set_request_to_render_as_odt(env) 
        @options = @options.merge(:to => 'odt')
      elsif render_as_docx?
        set_request_to_render_as_docx(env) 
        @options = @options.merge(:to => 'docx')
      end

      status, headers, response = @app.call(env)

      if (rendering_odt? || rendering_docx?) && headers['Content-Type'] =~ /text\/html|application\/xhtml\+xml/
        body = response.respond_to?(:body) ? response.body : response.join
        body = body.join if body.is_a?(Array)
        body = PanHandler.new(translate_paths(body, env), @options).to_data
        response = [body]

        # Do not cache ODTs
        headers.delete('ETag')
        headers.delete('Cache-Control')

        headers['Content-Length'] = (body.respond_to?(:bytesize) ? body.bytesize : body.size).to_s
        headers['Content-Type'] = content_type || headers['Content-Type']
      end

      [status, headers, response]
    end

    private

    def content_type
      if rendering_docx?
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      elsif rendering_odt?
        'application/vnd.oasis.opendocument.text'
      end
    end

    # Change relative paths to absolute
    def translate_paths(body, env)
      # Host with protocol
      root_path = PanHandler.configuration.root_path || ''
      rel_path = env['REQUEST_URI'][/#{env['HTTP_HOST']}(.*)\//,1] || '/'
      body.gsub(/(href|src)=(['"])([^\"']*|[^"']*)['"](\s?)/) do |match|
        attr, delim, value, trailing = $1, $2, $3, $4
        if value =~ /^http:\/\//i
          # absolute url
          ''
        else
          file_path = root_path
          # relative path
          file_path = File.join(file_path, rel_path) if value[0] != '/'
          # remove a possible query string
          file_path = File.join(file_path, value[/^(.*)\?/,1] || value)
          if File.exists?(file_path)
            "#{attr}=#{delim}#{file_path}#{delim}#{trailing || ''}"
          else
            ''
          end
        end
      end
    end

    def rendering_docx?
      @render_docx
    end

    def rendering_odt?
      @render_odt
    end

    def render_as_docx?
      render_as?('docx')
    end

    def render_as_odt?
      render_as?('odt')
    end

    def render_as?(format)
      request_path_is_format = @request.path.match(%r{\.#{format}$})

      if request_path_is_format && @conditions[:only]
        rules = [@conditions[:only]].flatten
        rules.any? do |pattern|
          if pattern.is_a?(Regexp)
            @request.path =~ pattern
          else
            @request.path[0, pattern.length] == pattern
          end
        end
      elsif request_path_is_format && @conditions[:except]
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
        request_path_is_format
      end
    end

    def set_request_to_render_as_docx(env)
      @render_docx = true
      set_request_to_render_as(env,'docx')
    end

    def set_request_to_render_as_odt(env)
      @render_odt = true
      set_request_to_render_as(env,'odt')
    end

    def set_request_to_render_as(env, format)
      path = @request.path.sub(%r{\.#{format}$}, '')
      %w[PATH_INFO REQUEST_URI].each { |e| env[e] = path }
      env['HTTP_ACCEPT'] = concat(env['HTTP_ACCEPT'], Rack::Mime.mime_type('.html'))
      env["Rack-Middleware-PanHandler"] = "true"
    end

    def concat(accepts, type)
      (accepts || '').split(',').unshift(type).compact.join(',')
    end

  end
end
