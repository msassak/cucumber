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
  end
end
