module Cucumber
  class Resource
    RESOURCE_COLON_LINE_PATTERN = /^([\w\W]*?):([\d:]+)$/ #:nodoc:

    def initialize(uri)
      @uri = uri
      _, _, @lines = *RESOURCE_COLON_LINE_PATTERN.match(@uri)
    end

    def path
      @uri
    end
    
    def lines
      @lines ? @lines.split(':').map{ |line| line.to_i } : nil
    end

    def format
      :gherkin
    end

    def protocol
      :file
    end
  end
end
