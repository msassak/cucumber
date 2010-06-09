require 'uri'

module Cucumber
  class Resource
    RESOURCE_COLON_LINE_PATTERN = /^([\w\W]*?):([\d:]+)$/ #:nodoc:

    attr_reader :uri

    def initialize(uri)
      @uri = URI.parse(URI.escape(uri))
    end

    def path
      uri.to_s.gsub(/\+[\w\W]+:\/\//, '://').gsub(/(:\d+)+$/, '')
    end
    
    def lines
      _, @path, @lines = *RESOURCE_COLON_LINE_PATTERN.match(uri.to_s)
      if @path
        @lines = @lines.split(':').map { |line| line.to_i }
      end
      @lines
    end

    def format
      _, format = (uri.scheme || "file+gherkin").split('+')
      format ? format.to_sym : :gherkin
    end

    def protocol
      (uri.scheme || "file").split("+")[0].to_sym
    end
  end
end
