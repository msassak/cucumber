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
        @registry ||= { :readers => [] }
      end

      def clear_registry
        @registry = nil
      end
    end

    # Plugins depend on the ResourceLoader and registry, so we
    # must require the default plugins after the ResourceLoader
    require 'cucumber/default_reader'
    require 'cucumber/gherkin_parser'

    RESOURCE_COLON_LINE_PATTERN = /^([\w\W]*?):([\d:]+)$/ #:nodoc:

    include Formatter::Duration
    attr_accessor :log, :options

    def load_resources(feature_files, feature_suite = Ast::Features.new)
      lists, singletons = feature_files.partition{ |res| res =~ /^@/ }
      lists.map! { |list| list.gsub(/^@/, '') }
      singletons += lists.collect{ |list| reader_for(list).list(list) }.flatten

      start = Time.new
      log.debug("Features:\n")
      singletons.each do |uri|
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
      Cucumber::GherkinParser.new.parse(content, path, lines, options)
    end

    def reader_for(path)
      uri = URI.parse(URI.escape(path))
      proto = (uri.scheme || :file).to_sym
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
  end
end
