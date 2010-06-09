require 'cucumber/plugin'
require 'open-uri'

module Cucumber
  class Reader
    extend Cucumber::Plugin
    register_reader(self)

    def protocols
      [:file, :http, :https]
    end

    def read(uri)
      if uri =~ /^http/
        open(uri).read
      else
        begin
          File.open(uri, Cucumber.file_mode('r')).read 
        rescue Errno::EACCES => e
          p = File.expand_path(uri)
          e.message << "\nCouldn't open #{p}"
          raise e
        end
      end
    end

    def list(uri)
      read(uri).split
    end
  end
end
