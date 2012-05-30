require 'spec_helper'

def app; Rack::Lint.new(@app); end

def mock_app(options = {}, conditions = {})
  main_app = lambda { |env|
    @env = env
    headers = {'Content-Type' => "text/html"}
    [200, headers, @body || ['Hello world!']]
  }

  builder = Rack::Builder.new
  builder.use PanHandler::Middleware, options, conditions
  builder.run main_app
  @app = builder.to_app
end


describe PanHandler::Middleware do

  describe "#call" do
    describe "conditions" do
      describe ":only" do

        describe "regex" do
          describe "one" do
            before { mock_app({}, :only => %r[^/public]) }

            context "matching" do
              specify do
                get 'http://www.example.org/public/test.odt'
                last_response.headers["Content-Type"].should == "application/vnd.oasis.opendocument.text"
                last_response.body.bytesize.should == PanHandler.new("Hello world!", :to => 'odt').to_data.bytesize
              end
              specify do
                get 'http://www.example.org/public/test.docx'
                last_response.headers["Content-Type"].should == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                last_response.body.bytesize.should == PanHandler.new("Hello world!", :to => 'docx').to_data.bytesize
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.odt'
                last_response.headers["Content-Type"].should == "text/html"
                last_response.body.should == "Hello world!"
              end
              specify do
                get 'http://www.example.org/secret/test.docx'
                last_response.headers["Content-Type"].should == "text/html"
                last_response.body.should == "Hello world!"
              end
            end
          end # one regex

          describe "multiple" do
            before { mock_app({}, :only => [%r[^/invoice], %r[^/public]]) }

            context "matching" do
              specify do
                get 'http://www.example.org/public/test.odt'
                last_response.headers["Content-Type"].should == "application/vnd.oasis.opendocument.text"
                last_response.body.bytesize.should == PanHandler.new("Hello world!", :to => 'odt').to_data.bytesize
              end
              specify do
                get 'http://www.example.org/public/test.docx'
                last_response.headers["Content-Type"].should == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                last_response.body.bytesize.should == PanHandler.new("Hello world!", :to => 'docx').to_data.bytesize
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.odt'
                last_response.headers["Content-Type"].should == "text/html"
                last_response.body.should == "Hello world!"
              end
              specify do
                get 'http://www.example.org/secret/test.docx'
                last_response.headers["Content-Type"].should == "text/html"
                last_response.body.should == "Hello world!"
              end
            end
          end # multiple regex
        end # regex

        describe "string" do
          describe "one" do
            before { mock_app({}, :only => '/public') }

            context "matching" do
              specify do
                get 'http://www.example.org/public/test.odt'
                last_response.headers["Content-Type"].should == "application/vnd.oasis.opendocument.text"
                last_response.body.bytesize.should == PanHandler.new("Hello world!", :to => 'odt').to_data.bytesize
              end
              specify do
                get 'http://www.example.org/public/test.docx'
                last_response.headers["Content-Type"].should == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                last_response.body.bytesize.should == PanHandler.new("Hello world!", :to => 'docx').to_data.bytesize
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.odt'
                last_response.headers["Content-Type"].should == "text/html"
                last_response.body.should == "Hello world!"
              end
              specify do
                get 'http://www.example.org/secret/test.docx'
                last_response.headers["Content-Type"].should == "text/html"
                last_response.body.should == "Hello world!"
              end
            end
          end # one string

          describe "multiple" do
            before { mock_app({}, :only => ['/invoice', '/public']) }

            context "matching" do
              specify do
                get 'http://www.example.org/public/test.odt'
                last_response.headers["Content-Type"].should == "application/vnd.oasis.opendocument.text"
                last_response.body.bytesize.should == PanHandler.new("Hello world!", :to => 'odt').to_data.bytesize
              end
              specify do
                get 'http://www.example.org/public/test.docx'
                last_response.headers["Content-Type"].should == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                last_response.body.bytesize.should == PanHandler.new("Hello world!", :to => 'docx').to_data.bytesize
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.odt'
                last_response.headers["Content-Type"].should == "text/html"
                last_response.body.should == "Hello world!"
              end
              specify do
                get 'http://www.example.org/secret/test.docx'
                last_response.headers["Content-Type"].should == "text/html"
                last_response.body.should == "Hello world!"
              end
            end
          end # multiple string
        end # string

      end

      describe ":except" do

        describe "regex" do
          describe "one" do
            before { mock_app({}, :except => %r[^/secret]) }

            context "matching" do
              specify do
                get 'http://www.example.org/public/test.odt'
                last_response.headers["Content-Type"].should == "application/vnd.oasis.opendocument.text"
                last_response.body.bytesize.should == PanHandler.new("Hello world!").to_data.bytesize
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.odt'
                last_response.headers["Content-Type"].should == "text/html"
                last_response.body.should == "Hello world!"
              end
            end
          end # one regex

          describe "multiple" do
            before { mock_app({}, :except => [%r[^/prawn], %r[^/secret]]) }

            context "matching" do
              specify do
                get 'http://www.example.org/public/test.odt'
                last_response.headers["Content-Type"].should == "application/vnd.oasis.opendocument.text"
                last_response.body.bytesize.should == PanHandler.new("Hello world!").to_data.bytesize
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.odt'
                last_response.headers["Content-Type"].should == "text/html"
                last_response.body.should == "Hello world!"
              end
            end
          end # multiple regex
        end # regex

        describe "string" do
          describe "one" do
            before { mock_app({}, :except => '/secret') }

            context "matching" do
              specify do
                get 'http://www.example.org/public/test.odt'
                last_response.headers["Content-Type"].should == "application/vnd.oasis.opendocument.text"
                last_response.body.bytesize.should == PanHandler.new("Hello world!").to_data.bytesize
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.odt'
                last_response.headers["Content-Type"].should == "text/html"
                last_response.body.should == "Hello world!"
              end
            end
          end # one string

          describe "multiple" do
            before { mock_app({}, :except => ['/prawn', '/secret']) }

            context "matching" do
              specify do
                get 'http://www.example.org/public/test.odt'
                last_response.headers["Content-Type"].should == "application/vnd.oasis.opendocument.text"
                last_response.body.bytesize.should == PanHandler.new("Hello world!").to_data.bytesize
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.odt'
                last_response.headers["Content-Type"].should == "text/html"
                last_response.body.should == "Hello world!"
              end
            end
          end # multiple string
        end # string

      end
    end

    describe "remove .odt from PATH_INFO and REQUEST_URI" do
      before { mock_app }

      context "matching" do
        specify do
          get 'http://www.example.org/public/file.odt'
          @env["PATH_INFO"].should == "/public/file"
          @env["REQUEST_URI"].should == "/public/file"
        end
        specify do
          get 'http://www.example.org/public/file.txt'
          @env["PATH_INFO"].should == "/public/file.txt"
          @env["REQUEST_URI"].should be_nil
        end
      end

    end
  end

  describe "#translate_paths of absolute urls" do
    before do
      @odt = PanHandler::Middleware.new({})
      @env = { 'REQUEST_URI' => 'http://example.com/document.odt', 'rack.url_scheme' => 'http', 'HTTP_HOST' => 'example.com' }
    end

    it "should correctly parse with single quotes" do
      @body = %{<html><head><link href='http://example.com/stylesheets/application.css' media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' src="HTTP://example.com/test.png" /></body></html>}
      body = @odt.send :translate_paths, @body, @env
      body.should == "<html><head><link media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' /></body></html>"
    end

    it "should correctly parse with double quotes" do
      @body = %{<link href="http://example.com/stylesheets/application.css" media="screen" rel="stylesheet" type="text/css" />}
      body = @odt.send :translate_paths, @body, @env
      body.should == "<link media=\"screen\" rel=\"stylesheet\" type=\"text/css\" />"
    end

    it "should return the body even if there are no valid substitutions found" do
      @body = "NO MATCH"
      body = @odt.send :translate_paths, @body, @env
      body.should == "NO MATCH"
    end
  end

   describe "#translate_paths of absolute files that do not exists" do
    before do
      @odt = PanHandler::Middleware.new({})
      @env = { 'REQUEST_URI' => 'http://example.com/document.odt', 'rack.url_scheme' => 'http', 'HTTP_HOST' => 'example.com' }
    end

    it "should correctly parse relative url with single quotes" do
      @body = %{<html><head><link href='/does_not_exist.css' media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' src="/does_not_exist.png" /></body></html>}
      body = @odt.send :translate_paths, @body, @env
      body.should == "<html><head><link media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' /></body></html>"
    end

    it "should correctly parse relative url with double quotes" do
      @body = %{<link href="/does_not_exist.css" media="screen" rel="stylesheet" type="text/css" />}
      body = @odt.send :translate_paths, @body, @env
      body.should == "<link media=\"screen\" rel=\"stylesheet\" type=\"text/css\" />"
    end
   end
  
  describe "#translate_paths with root_path configuration" do
    before do
      @odt = PanHandler::Middleware.new({})
      @env = { 'REQUEST_URI' => 'http://example.com/document.odt', 'rack.url_scheme' => 'http', 'HTTP_HOST' => 'example.com' }
      @root = File.dirname(__FILE__)
      PanHandler.configure do |config|
        config.root_path = @root
      end
    end

    it "should add the root_path" do
      @body = %{<html><head><link href='/fixtures/example.css' media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' src="/fixtures/test.jpg" /></body></html>}
      body = @odt.send :translate_paths, @body, @env
      body.should == "<html><head><link href='#{@root}/fixtures/example.css' media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' src=\"#{@root}/fixtures/test.jpg\" /></body></html>"
    end
    
    after do
      PanHandler.configure do |config|
        config.root_path = nil
      end
    end
  end

  describe "#translate_paths with relative files"
  describe "#translate_paths with query strings"

  it "should not get stuck rendering each request as odt" do
    mock_app
    # false by default. No requests.
    @app.send(:rendering_odt?).should be_false

    # Remain false on a normal request
    get 'http://www.example.org/public/file'
    @app.send(:rendering_odt?).should be_false

    # Return true on a odt request.
    get 'http://www.example.org/public/file.odt'
    @app.send(:rendering_odt?).should be_true

    # Restore to false on any non-odt request.
    get 'http://www.example.org/public/file'
    @app.send(:rendering_odt?).should be_false
  end

end
