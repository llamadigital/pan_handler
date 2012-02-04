class PanHandler
  class Configuration
    attr_accessor :meta_tag_prefix, :default_options, :root_url
    attr_writer :pandoc

    def initialize
      @default_options = {
        :from => 'html',
        :to => 'odt',
        :reference_odt => nil,
      }
    end

    def pandoc
      @pandoc ||= (defined?(Bundler::GemfileError) ? `bundle exec which pandoc` : `which pandoc`).chomp
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
