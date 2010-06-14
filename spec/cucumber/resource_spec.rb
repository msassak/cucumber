require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

require 'cucumber/resource'

module Cucumber
  describe Resource do
    describe "a vanilla resource" do
      subject        { Resource.new("features/example.feature") }
      its(:path)     { should == "features/example.feature" }
      its(:lines)    { should be_nil }
      its(:format)   { should == :gherkin }
      its(:protocol) { should == :file }
    end

    describe "a resource with protocol" do
      subject        { Resource.new("http://example.com/example.feature") }
      its(:path)     { should == "http://example.com/example.feature" }
      its(:format)   { should == :gherkin }
      its(:protocol) { should == :http }
    end

    describe "a resource with protocol and format" do
      subject        { Resource.new("ftp+json://example.com/my.feature") }
      its(:path)     { should == "ftp://example.com/my.feature" }
      its(:format)   { should == :json }
      its(:protocol) { should == :ftp }
    end

    describe "a resource with protocol, format and lines" do
      subject        { Resource.new("git+textile://example.com/my.feature:6:98:2112") }
      its(:path)     { should == "git://example.com/my.feature" }
      its(:lines)    { should == [6, 98, 2112] }
      its(:format)   { should == :textile }
      its(:protocol) { should == :git }
    end

    describe "a resource with spaces in the name" do
      subject    { Resource.new("features/spaces are nasty.feature") }
      its(:path) { should == "features/spaces are nasty.feature" }
    end

    it "parses a resource without a scheme and with line numbers" do
      res = Resource.new("example.feature:10:20:110")
      res.protocol.should == :file
    end
  end
end
