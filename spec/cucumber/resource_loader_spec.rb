require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'cucumber'

module Cucumber
  describe ResourceLoader do
    before do
      @file_loader = mock('file input service', :read => "Feature: test", :protocols => [:file])
      #Inputs::File.stub!(:new).and_return(@file_input)

      @http_loader = mock('http input service', :read => "Feature: test", :protocols => [:http, :https])
      #Inputs::HTTP.stub!(:new).and_return(@http_input)

      @gherkin_parser = mock('gherkin parser', :parse => mock('feature', :features= => true, :adverbs => []), :format => :treetop)
      #Parsers::Treetop.stub!(:new).and_return(@gherkin_parser)
      
      @textile_parser = mock('textile parser', :parse => mock('feature', :adverbs => [], :features= => true), :format => :textile)
      
      @out = StringIO.new
      @log = Logger.new(@out)

      @resource_loader = ResourceLoader.new
      @resource_loader.log = @log
      @resource_loader.options = mock('options', :filters => [])
      @resource_loader.register_loader(@file_loader)
      @resource_loader.register_loader(@http_loader)
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
        
    describe "#load_resource" do
      it "splits the path from line numbers" do
        @file_loader.should_receive(:read).with("example.feature")
        @resource_loader.load_resource("example.feature:10:20")
      end
      
      it "reads a feature from a file" do
        @file_loader.should_receive(:read).with("example.feature").once
        @resource_loader.load_resource("example.feature")
      end

      it "loads a feature from a file with spaces in the name" do
        @file_loader.should_receive(:read).with("features/spaces are nasty.feature").once
        @resource_loader.load_resource("features/spaces are nasty.feature")
      end

      it "raises if it has no input service for the protocol" do
        lambda {
         @resource_loader.load_resource("accidentally://the.whole/thing.feature") 
        }.should raise_error(LoaderNotFound, /.*'accidentally'.*Services available:.*/)
      end
    end
        
    describe "#load_resources" do
      it "loads features from multiple input sources" do
        @http_loader.should_receive(:read).with("http://test.domain/http.feature").once
        @file_loader.should_receive(:read).with("example.feature").once
        @resource_loader.load_resources(["example.feature", "http://test.domain/http.feature"])
      end
    end
    
    it "says what protocols it supports" do
      @resource_loader.protocols.should include(:http, :https, :file)
    end
    
    xit "should parse a feature written in Gherkin" do
      @gherkin_parser.should_receive(:parse).once
      @resource_loader.load_feature("example.feature")
    end
    
    xit "should default to the Gherkin format" do
      @gherkin_parser.should_receive(:parse).once
      @resource_loader.load_feature("jbehave.scenario")
    end
    
    xit "should assume the Gherkin format if there is no extension" do
      @gherkin_parser.should_receive(:parse).once
      @resource_loader.load_feature("example")
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
    
    xit "should pull feature names from a feature list" do
      @file_input.should_receive(:list).with("my_feature_list.txt").and_return(["features/foo.feature", "features/bar.feature"])
      @resource_loader.load_features(["@my_feature_list.txt"])
    end
  end
end
