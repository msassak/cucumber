require 'cucumber/formatter/duration'
require 'open-uri'

module Cucumber
  class ResourceLoader
    include Formatter::Duration
    attr_accessor :log, :options

    def load_resources(feature_files)
      lists, singletons = feature_files.partition{ |res| res =~ /^@/ }
      singletons += lists.collect{ |list| open(list.gsub(/^@/, '')).readlines}.flatten

      features = Ast::Features.new

      start = Time.new
      log.debug("Features:\n")
      singletons.each do |f|
        feature_file = FeatureFile.new(f)
        feature = feature_file.parse(options)
        if feature
          features.add_feature(feature)
          log.debug("  * #{f}\n")
        end
      end
      duration = Time.now - start
      log.debug("Parsing feature files took #{format_duration(duration)}\n\n")
      features
    end
  end
end

require 'gherkin/parser/filter_listener'
require 'gherkin/parser/parser'
require 'gherkin/i18n_lexer'

module Cucumber
  class FeatureFile
    FILE_COLON_LINE_PATTERN = /^([\w\W]*?):([\d:]+)$/ #:nodoc:
    LANGUAGE_PATTERN = /language:\s*(.*)/ #:nodoc:

    # The +uri+ argument is the location of the source. It can ba a path 
    # or a path:line1:line2 etc. If +source+ is passed, +uri+ is ignored.
    def initialize(uri, source=nil)
      @source = source
      _, @path, @lines = *FILE_COLON_LINE_PATTERN.match(uri)
      if @path
        @lines = @lines.split(':').map { |line| line.to_i }
      else
        @path = uri
      end
    end
    
    # Parses a file and returns a Cucumber::Ast
    # If +options+ contains tags, the result will
    # be filtered.
    def parse(options)
      filters = @lines || options.filters

      builder         = Cucumber::Ast::Builder.new
      filter_listener = Gherkin::Parser::FilterListener.new(builder, filters)
      parser          = Gherkin::Parser::Parser.new(filter_listener, true, "root")
      lexer           = Gherkin::I18nLexer.new(parser, false)

      begin
        s = ENV['FILTER_PML_CALLOUT'] ? source.gsub(C_CALLOUT, '') : source
        lexer.scan(s)
        ast = builder.ast
        return nil if ast.nil? # Filter caused nothing to match
        ast.language = lexer.i18n_language
        ast.file = @path
        ast
      rescue Gherkin::LexingError, Gherkin::Parser::ParseError => e
        e.message.insert(0, "#{@path}: ")
        raise e
      end
    end

    def source
      @source ||= if @path =~ /^http/
        require 'open-uri'
        open(@path).read
      else
        begin
          File.open(@path, Cucumber.file_mode('r')).read 
        rescue Errno::EACCES => e
          p = File.expand_path(@path)
          e.message << "\nCouldn't open #{p}"
          raise e
        end
      end
    end
    
    private
    
    # Special PML markup that we want to filter out.
    CO = %{\\s*<(label|callout)\s+id=".*?"\s*/>\\s*}
    C_CALLOUT = %r{/\*#{CO}\*/|//#{CO}}o
  end
end
