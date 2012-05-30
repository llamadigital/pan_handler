require 'tempfile'

class PanHandler

  class NoExecutableError < StandardError
    def initialize
      msg  = "No pandoc executable found at #{PanHandler.configuration.pandoc}\n"
      msg << ">> Please install pandoc"
      super(msg)
    end
  end

  class ImproperSourceError < StandardError
    def initialize(msg)
      super("Improper Source: #{msg}")
    end
  end

  attr_accessor :source
  attr_reader :options

  def initialize(url_file_or_html, options = {})
    @source = Source.new(url_file_or_html)
    @options = PanHandler.configuration.default_options.merge(options)
    @options = normalize_options(@options)

    if PanHandler.configuration.pandoc.nil? || !File.exists?(PanHandler.configuration.pandoc)
      raise NoExecutableError.new 
    end
  end

  def command(path = nil)
    args = [executable]
    args += @options.to_a.flatten.compact

    args << '--output'
    args << (path || '-') # Write to file or stdout

    unless @source.html?
      args << @source.to_s
    end

    args.map {|arg| %Q{"#{arg.gsub('"', '\"')}"}}
  end

  def executable
    default = PanHandler.configuration.pandoc
    return default if default !~ /^\// # its not a path, so nothing we can do
    if File.exist?(default)
      default
    else
      default.split('/').last
    end
  end

  def to_odt(path=nil)
    to_data(path)
  end


  def to_file(path)
    self.to_data(path)
    File.new(path)
  end

  def to_data(path=nil)
    if path.nil?
      tempfile = Tempfile.new('panhandler')
      path = tempfile.path
    end
    args = command(path)
    invoke = args.join(' ')

    result = IO.popen(invoke, "wb+") do |odt|
      odt.puts(@source.to_s) if @source.html?
      odt.close_write
      odt.gets(nil)
    end
    result = File.read(path) if path
    tempfile.unlink if tempfile

    raise "command failed: #{invoke}" if result.empty?
    return result
  end

  protected

  def normalize_options(options)
    normalized_options = {}

    options.each do |key, value|
      next if !value
      normalized_key = "--#{normalize_arg key}"
      normalized_options[normalized_key] = normalize_value(value)
    end
    normalized_options
  end

  def normalize_arg(arg)
    arg.to_s.downcase.gsub(/[^a-z0-9]/,'-')
  end

  def normalize_value(value)
    case value
    when TrueClass
      nil
    else
      value.to_s
    end
  end

end
