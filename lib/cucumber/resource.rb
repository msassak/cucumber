module Cucumber
  class Resource
    RESOURCE_COLON_LINE_PATTERN = /^([\w\W]*?):([\d:]+)$/ #:nodoc:

    attr_reader :path, :lines

    def initialize(uri)
      _, @path, @lines = *RESOURCE_COLON_LINE_PATTERN.match(uri)
      if @path
        @lines = @lines.split(':').map { |line| line.to_i }
      else
        @path = uri
      end
    end

    def format
      :gherkin
    end

    def protocol
      :file
    end
  end
end
