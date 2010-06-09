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
      its(:uri)      { should == "ftp+json://example.com/my.feature" }
      its(:format)   { should == :json }
      its(:protocol) { should == :ftp }
    end

    describe "a resource with protocol, format and lines" do
      subject        { Resource.new("git+textile://example.com/my.feature:6:98:2112") }
      its(:lines)    { should == [6, 98, 2112] }
      its(:format)   { should == :textile }
      its(:protocol) { should == :git     }
    end
  end
end
