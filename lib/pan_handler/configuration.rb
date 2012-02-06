class PanHandler
  class Configuration
    attr_accessor :default_options, :root_path
    attr_writer :pandoc

    def initialize
      @default_options = {
        :from => 'html',
        :to => 'odt',
        :standalone => true
      }
    end

    def pandoc
      @pandoc ||= [which_pandoc_proxy, which_pandoc].find{ |c| not c.empty? }
    end

    private

    def which_pandoc
      (defined?(Bundler::GemfileError) ? `bundle exec which pandoc` : `which pandoc`).chomp
    end

    def which_pandoc_proxy
      (defined?(Bundler::GemfileError) ? `bundle exec which pandoc-proxy` : `which pandoc-proxy`).chomp
    end
  end

  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end

