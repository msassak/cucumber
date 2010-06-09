module Cucumber
  class Resource
    def initialize(uri)
      @uri = uri
    end

    def path
      @uri
    end
    
    def lines
      nil
    end

    def format
      :gherkin
    end

    def protocol
      :file
    end
  end
end
