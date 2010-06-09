require 'gherkin/parser/filter_listener'
require 'gherkin/parser/parser'
require 'gherkin/i18n_lexer'

module Cucumber
  class GherkinParser
    # Parses a file and returns a Cucumber::Ast
    # If +options+ contains tags, the result will
    # be filtered.
    def parse(content, path, lines, options)
      filters = lines || options.filters

      builder         = Cucumber::Ast::Builder.new
      filter_listener = Gherkin::Parser::FilterListener.new(builder, filters)
      parser          = Gherkin::Parser::Parser.new(filter_listener, true, "root")
      lexer           = Gherkin::I18nLexer.new(parser, false)

      begin
        s = ENV['FILTER_PML_CALLOUT'] ? content.gsub(C_CALLOUT, '') : content
        lexer.scan(s)
        ast = builder.ast
        return nil if ast.nil? # Filter caused nothing to match
        ast.language = lexer.i18n_language
        ast.file = path
        ast
      rescue Gherkin::LexingError, Gherkin::Parser::ParseError => e
        e.message.insert(0, "#{path}: ")
        raise e
      end
    end

    private
    
    # Special PML markup that we want to filter out.
    CO = %{\\s*<(label|callout)\s+id=".*?"\s*/>\\s*}
    C_CALLOUT = %r{/\*#{CO}\*/|//#{CO}}o
  end
end
