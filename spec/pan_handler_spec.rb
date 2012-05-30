#encoding: UTF-8
require 'spec_helper'
require 'tempfile'

describe PanHandler do

  context "initialization" do
    it "should accept HTML as the source" do
      panhandler = PanHandler.new('<h1>Oh Hai</h1>')
      panhandler.source.should be_html
      panhandler.source.to_s.should == '<h1>Oh Hai</h1>'
    end

    it "should accept a URL as the source" do
      panhandler = PanHandler.new('http://google.com')
      panhandler.source.should be_url
      panhandler.source.to_s.should == 'http://google.com'
    end

    it "should accept a File as the source" do
      file_path = File.join('spec','fixtures','example.html')
      panhandler = PanHandler.new(File.new(file_path))
      panhandler.source.should be_file
      panhandler.source.to_s.should == file_path
    end

    it "should parse the options into a cmd line friendly format" do
      panhandler = PanHandler.new('html', :reference_odt => 'reference')
      panhandler.options.should have_key('--reference-odt')
    end

    it "should provide default options" do
      panhandler = PanHandler.new('<h1>Oh Hai</h1>')
      ['--from', '--to'].each do |option|
        panhandler.options.should have_key(option)
      end
    end
  end

  context "command" do
    it "should contstruct the correct command" do
      panhandler = PanHandler.new('html', :from => 'html', :to => 'odt', :reference_odt => 'reference')
      panhandler.command[0].should include('pandoc')
      panhandler.command[panhandler.command.index('"--from"') + 1].should == '"html"'
      panhandler.command[panhandler.command.index('"--to"') + 1].should == '"odt"'
      panhandler.command[panhandler.command.index('"--reference-odt"') + 1].should == '"reference"'
    end

    it "should encapsulate string arguments in quotes" do
      panhandler = PanHandler.new('html', :reference_odt => "i am a reference file.odt")
      panhandler.command[panhandler.command.index('"--reference-odt"') + 1].should == '"i am a reference file.odt"'
    end

    it "read the source from stdin if it is html" do
      panhandler = PanHandler.new('html')
      panhandler.command[-1].should_not be == 'html'
    end

    it "specify the URL to the source if it is a url" do
      panhandler = PanHandler.new('http://google.com')
      panhandler.command[-1].should == '"http://google.com"'
    end

    it "should specify the path to the source if it is a file" do
      file_path = File.join('spec','fixtures','example.html')
      panhandler = PanHandler.new(File.new(file_path))
      panhandler.command[-1].should be == %Q{"#{file_path}"}
    end

    it "should specify the path for the ouput if a path is given" do
      file_path = "/path/to/output.odt"
      panhandler = PanHandler.new("html")
      panhandler.command(file_path)[-1].should be == %Q{"#{file_path}"}
    end
  end

  context "#to_odt" do

    before { @tempfile = Tempfile.new('panhandler') }
    after { @tempfile.unlink if @tempfile }

    [ PanHandler.new("<html><head></head><body>Hai!</body></html>"),
      PanHandler.new('http://google.com'),
      PanHandler.new(File.new(File.join('spec','fixtures','example.html')))
    ].each do |panhandler|
      it "should generate an ODT of HTML" do
        odt = panhandler.to_odt(@tempfile.path)
        odt[0..1].should == "PK"
      end
    end

  end

  context "#to_file" do

    before { @tempfile = Tempfile.new('panhandler') }
    after { @tempfile.unlink if @tempfile }

    [
      '<html><head></head><body>Hai!</body></html>',
      'http://google.com',
      File.new(File.join('spec','fixtures','example.html'))
    ].each do |source|
      it "should generate an ODT of HTML" do
        panhandler = PanHandler.new(source, :to => 'odt')
        file = panhandler.to_file(@tempfile.path)
        file.should be_instance_of(File)
        File.exists?(file).should be_true
        file.size.should be > 0
        File.read(file)[0..1].should == "PK"
      end

      it "should generate a DOCX of HTML" do
        panhandler = PanHandler.new(source, :to => 'docx')
        file = panhandler.to_file(@tempfile.path)
        file.should be_instance_of(File)
        File.exists?(file).should be_true
        file.size.should be > 0
        # File.read(file)[0..1].should == "PK"
      end
    end

  end

end
