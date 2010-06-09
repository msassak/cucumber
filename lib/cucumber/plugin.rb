module Cucumber
  module Plugin
    def register_reader(reader_class)
      ResourceLoader.registry[:readers] << reader_class
    end

    def register_parser(parser_class)
      ResourceLoader.registry[:parsers] << parser_class
    end
  end
end
