require 'cucumber/formatter/duration'
require 'uri'

module Cucumber
  class ReaderNotFound < StandardError
    def initialize(proto, available)
      super "No reader service for the '#{proto}' protocol has been registered. Protocols available: #{available.join(', ')}."
    end
  end
 
  class ResourceLoader
    class << self
      def registry
        @registry ||= { :readers => [], :parsers => [] }
      end

      def clear_registry
        @registry = nil
      end
    end

    # Plugins depend on the ResourceLoader and registry, so we
    # must require the default plugins after the ResourceLoader
    require 'cucumber/reader'
    require 'cucumber/gherkin_parser'

    RESOURCE_COLON_LINE_PATTERN = /^([\w\W]*?):([\d:]+)$/ #:nodoc:

    include Formatter::Duration
    attr_accessor :log, :options

    def load_resources(uris, feature_suite = Ast::Features.new)
      all_uris = expand_uris(uris)
      
      start = Time.new
      log.debug("Features:\n")
      all_uris.each do |uri|
        feature = load_resource(uri)
        if feature
          feature_suite.add_feature(feature)
          log.debug("  * #{uri}\n")
        end
      end
      duration = Time.now - start
      log.debug("Parsing feature files took #{format_duration(duration)}\n\n")
      feature_suite
    end
    
    def load_resource(uri)
      _, path, lines = *RESOURCE_COLON_LINE_PATTERN.match(uri)
      if path
        lines = lines.split(':').map { |line| line.to_i }
      else
        path = uri
      end

      content = reader_for(path).read(path)
      parser_for(path).parse(content, path, lines, options)
    end

    def reader_for(path)
      uri = URI.parse(URI.escape(path))
      proto = (uri.scheme || "file+gherkin").split('+')[0].to_sym
      readers[proto] || raise(ReaderNotFound.new(proto, protocols))
    end

    def readers
      return @readers if @readers
      @readers = {}
      self.class.registry[:readers].each do |reader_class|
        reader = reader_class.new
        reader.protocols.each do |proto|
          @readers[proto] = reader
        end
      end
      @readers
    end

    def protocols
      readers.keys
    end

    def parser_for(path)
      uri = URI.parse(URI.escape(path))
      _, format = (uri.scheme || "file+gherkin").split('+')
      parsers[format ? format.to_sym : :gherkin]
    end

    def parsers
      return @parsers if @parsers
      @parsers = {}
      self.class.registry[:parsers].each do |parser_class|
        parser = parser_class.new
        @parsers[parser.format] = parser
      end
      @parsers
    end

    def expand_uris(uris)
      lists, singletons = uris.partition{ |res| res =~ /^@/ }
      lists.map! { |list| list.gsub(/^@/, '') }
      singletons += lists.collect{ |list| reader_for(list).list(list) }.flatten
    end
  end
end
