module Cucumber
  module Plugin
    def register_reader(reader_class)
      ResourceLoader.registry[:readers] << reader_class
    end
  end
end
