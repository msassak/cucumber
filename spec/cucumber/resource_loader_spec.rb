require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'cucumber/resource_loader'
require 'cucumber/reader'
require 'cucumber/gherkin_parser'

module Cucumber
  describe ResourceLoader do
    before do
      @reader = mock('default reader service', :read => "Feature: test", :protocols => [:file, :http, :https])
      Reader.stub!(:new).and_return(@reader)

      @gherkin_parser = mock('gherkin parser', :parse => mock('feature', :features= => true, :adverbs => []), :format => :gherkin)
      GherkinParser.stub!(:new).and_return(@gherkin_parser)
      
      @textile_parser = mock('textile parser', :parse => mock('feature', :adverbs => [], :features= => true), :format => :textile)
      
      @resource_loader = ResourceLoader.new
      @resource_loader.log = Logger.new(StringIO.new)
      @resource_loader.options = mock('options', :filters => [])
    end

    def register_parser(parser, &block)
      ResourceLoader.registry[:parsers].push mock('plugin class', :new => parser)
      block.call
      ResourceLoader.registry[:parsers].pop
    end

    def resource(path)
      Resource.new(path)
    end
    
    describe "loading resources" do
      it "splits the path from line numbers" do
        @reader.should_receive(:read).with("example.feature")
        @resource_loader.load_resource(resource("example.feature:10:20"))
      end
      
      it "reads a feature from a file" do
        @reader.should_receive(:read).with("example.feature").once
        @resource_loader.load_resource(resource("example.feature"))
      end

      it "loads a feature from a file with spaces in the name" do
        @reader.should_receive(:read).with("features/spaces are nasty.feature").once
        @resource_loader.load_resource(resource("features/spaces are nasty.feature"))
      end

      it "raises if it has no input service for the protocol" do
        lambda {
         @resource_loader.load_resource(resource("accidentally://the.whole/thing.feature"))
        }.should raise_error(ReaderNotFound, /.*'accidentally'.*Protocols available:.*/)
      end

      it "loads features from multiple input sources" do
        @reader.should_receive(:read).with("example.feature").ordered
        @reader.should_receive(:read).with("http://test.domain/http.feature").ordered
        @resource_loader.load_resources(["example.feature", "http://test.domain/http.feature"])
      end
      
      it "retrieves resource names from a list" do
        @reader.should_receive(:list).with("my_feature_list.txt").and_return(["features/foo.feature", "features/bar.feature"])
        @resource_loader.load_resources(["@my_feature_list.txt"])
      end
    end

    it "says what protocols it supports" do
      @resource_loader.protocols.should include(:http, :https, :file)
    end
    
    it "defaults to the Gherkin parser" do
      @gherkin_parser.should_receive(:parse).once
      @resource_loader.load_resource(resource("jbehave.scenario"))
    end
    
    it "should assume the Gherkin format if there is no extension" do
      @gherkin_parser.should_receive(:parse).once
      @resource_loader.load_resource(resource("example"))
    end
    
    it "should determine the feature format by the URI scheme" do
      @textile_parser.should_receive(:parse).with(anything(), "file+textile://example.textile", anything(), anything()).once
      @gherkin_parser.should_receive(:parse).with(anything(), "example.feature", anything(), anything()).once
      
      register_parser(@textile_parser) do
        @resource_loader.load_resources(["example.feature", "file+textile://example.textile"])
      end
    end

    it "raises ParserNotFound if no parser exists for the format" do
      lambda do 
        @resource_loader.load_resources(["file+dne://example.feature"])
      end.should raise_error(ParserNotFound)
    end
       
    it "says what formats it can parse" do
      @resource_loader.formats.should include(:gherkin)
    end
  end
end
