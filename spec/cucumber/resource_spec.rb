require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

require 'cucumber/resource'

module Cucumber
  describe Resource do
    describe "a vanilla resource" do
      subject        { Resource.new("example.feature") }
      its(:path)     { should == "example.feature" }
      its(:lines)    { should be_nil }
      its(:format)   { should == :gherkin }
      its(:protocol) { should == :file }
    end

    describe "a resource with specific lines" do
      subject { Resource.new("example.feature:6:98:113") }
      its(:lines) { should == [6, 98, 113] }
    end
  end
end
