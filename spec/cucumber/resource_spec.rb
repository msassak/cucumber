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

    describe "a resource with specific lines" do
      subject     { Resource.new("example.feature:6:98:113") }
      its(:path)  { should == "example.feature" }
      its(:lines) { should == [6, 98, 113] }
    end

    describe "a resource with a specified protocol" do
      subject        { Resource.new("http://example.feature") }
      its(:path)     { should == "http://example.feature" }
      its(:format)   { should == :gherkin }
      its(:protocol) { should == :http }
    end
  end
end
