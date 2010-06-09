require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'cucumber/resource_loader'
require 'cucumber/reader'
require 'cucumber/gherkin_parser'

module Cucumber
  describe ResourceLoader do
    before do
      @reader = mock('default reader service', :read => "Feature: test", :protocols => [:file, :http, :https])
      Reader.stub!(:new).and_return(@reader)

      @gherkin_parser = mock('gherkin parser', :parse => mock('feature', :features= => true, :adverbs => []), :format => :treetop)
      GherkinParser.stub!(:new).and_return(@gherkin_parser)
      
      @textile_parser = mock('textile parser', :parse => mock('feature', :adverbs => [], :features= => true), :format => :textile)
      
      @out = StringIO.new
      @log = Logger.new(@out)

      @resource_loader = ResourceLoader.new
      @resource_loader.log = @log
      @resource_loader.options = mock('options', :filters => [])
    end

    def register_parser(parser, &block)
      ResourceLoader.registry[:parsers].push mock('plugin class', :new => parser)
      block.call
      ResourceLoader.registry[:parsers].pop
    end
    
    def register_format_rules(rules, &block)
      ResourceLoader.registry[:format_rules].merge!(rules)
      block.call
      ResourceLoader.registry[:format_rules].clear
    end
        
    describe "loading resources" do
      it "splits the path from line numbers" do
        @reader.should_receive(:read).with("example.feature")
        @resource_loader.load_resource("example.feature:10:20")
      end
      
      it "reads a feature from a file" do
        @reader.should_receive(:read).with("example.feature").once
        @resource_loader.load_resource("example.feature")
      end

      it "loads a feature from a file with spaces in the name" do
        @reader.should_receive(:read).with("features/spaces are nasty.feature").once
        @resource_loader.load_resource("features/spaces are nasty.feature")
      end

      it "raises if it has no input service for the protocol" do
        lambda {
         @resource_loader.load_resource("accidentally://the.whole/thing.feature") 
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
      @resource_loader.load_resource("jbehave.scenario")
    end
    
    it "should assume the Gherkin format if there is no extension" do
      @gherkin_parser.should_receive(:parse).once
      @resource_loader.load_resource("example")
    end
    
    xit "should determine the feature format by the file extension" do
      @textile_parser.should_receive(:parse).with(anything(), "example.textile", anything(), anything()).once
      @gherkin_parser.should_receive(:parse).with(anything(), "example.feature", anything(), anything()).once
      
      register_parser(@textile_parser) do
        @resource_loader.load_features(["example.feature", "example.textile"])
      end
    end
            
    xit "should say it supports the formats parsed by a registered parser" do
      register_parser(@textile_parser) do
        @resource_loader.formats.should include(:textile)
      end
    end
        
    xit "should allow a format rule to override extension-based format determination" do
      @textile_parser.should_receive(:parse).once
      
      register_format_rules({/\.txt$/ => :textile}) do
        register_parser(@textile_parser) do
          @resource_loader.load_feature("example.txt")
        end
      end
    end
        
    xit "should allow format rules to enable parsing features with the same extension in different formats" do
      @textile_parser.should_receive(:parse).once
      @gherkin_parser.should_receive(:parse).once
            
      register_format_rules({/features\/test\/\w+\.feature$/ => :textile}) do
        register_parser(@textile_parser) do
          @resource_loader.load_feature("features/example.feature")
          @resource_loader.load_feature("features/test/example.feature")          
        end
      end
    end
    
    xit "should raise AmbiguousFormatRules if two or more format rules match" do
      register_format_rules({/\.foo$/ => :gherkin, /.*/ => :gherkin}) do
        lambda do
          @resource_loader.load_feature("example.foo")
        end.should raise_error(AmbiguousFormatRules)
      end
    end
  end
end
