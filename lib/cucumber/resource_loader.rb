require 'cucumber/formatter/duration'
require 'cucumber/resource'

module Cucumber
  class ReaderNotFound < StandardError
    def initialize(proto, available)
      super "No reader service for the '#{proto}' protocol has been registered. Protocols available: #{available.join(', ')}."
    end
  end

  class ParserNotFound < StandardError
    def initialize(format, available)
      super "No plugins service for the '#{format}' format has been registered. Formats available: #{available.join(', ')}."
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

    include Formatter::Duration
    attr_accessor :log, :options

    def load_resources(resource_uris, feature_suite = Ast::Features.new)
      all_uris = expand_uris(resource_uris)
      
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
    
    def load_resource(resource)
      content = reader_for(resource.protocol).read(resource.path)
      parser_for(resource.format).parse(content, resource.to_s, resource.lines, options)
    end

    def reader_for(proto)
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

    def parser_for(format)
      parsers[format] || raise(ParserNotFound.new(format, formats))
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

    def formats
      parsers.keys
    end

    def expand_uris(uris)
      lists, singletons = uris.partition{ |res| res =~ /^@/ }
      lists.map! { |list| list.gsub(/^@/, '') }
      
      singletons += lists.collect do |list| 
        resource = Resource.new(list)
        reader_for(resource.protocol).list(resource.path)
      end.flatten

      singletons.collect { |uri| Resource.new(uri) }
    end
  end
end
