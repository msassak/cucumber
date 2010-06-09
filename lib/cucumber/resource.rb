module Cucumber
  class Resource
    def initialize(uri)
      @uri = uri
    end

    def path
      @uri
    end
  end
end
