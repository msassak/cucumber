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
  end
end
