require 'uri'

module Cucumber
  class Resource
    RESOURCE_COLON_LINE_PATTERN = /^([\w\W]*?):([\d:]+)$/ #:nodoc:
    SCHEME_PATTERN = /^([\w\W]+):\/\// #:nodoc:

    attr_reader :uri, :protocol, :format

    def initialize(uri)
      @protocol, @format = extract_protocol_and_format(uri)
      @uri = URI.parse(URI.escape(uri))
    end

    def extract_protocol_and_format(uri)
      proto = fmt = nil
      _, scheme = *SCHEME_PATTERN.match(uri)
      proto, fmt = scheme.split('+').collect{|part| part.to_sym} if scheme
      [proto || :file, fmt || :gherkin]
    end

    def path
      URI.unescape(uri.to_s.gsub(/\+[\w\W]+:\/\//, '://').gsub(/(:\d+)+$/, ''))
    end
    
    def lines
      _, @path, @lines = *RESOURCE_COLON_LINE_PATTERN.match(uri.to_s)
      if @path
        @lines = @lines.split(':').map { |line| line.to_i }
      end
      @lines
    end
  end
end
