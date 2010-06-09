require 'uri'

module Cucumber
  class Resource
    RESOURCE_COLON_LINE_PATTERN = /^([\w\W]*?):([\d:]+)$/ #:nodoc:

    attr_reader :uri, :path, :lines

    def initialize(uri)
      @uri = uri
      _, @path, @lines = *RESOURCE_COLON_LINE_PATTERN.match(uri)
      if @path
        @lines = @lines.split(':').map { |line| line.to_i }
      else
        @path = uri.gsub(/\+[\w\W]+:\/\//, '://')
      end

    end

    def format
      u = URI.parse(URI.escape(uri))
      _, format = (u.scheme || "file+gherkin").split('+')
      format ? format.to_sym : :gherkin
    end

    def protocol
      uri = URI.parse(URI.escape(path))
      (uri.scheme || "file").split("+")[0].to_sym
    end
  end
end
