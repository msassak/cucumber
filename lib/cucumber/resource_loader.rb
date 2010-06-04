require 'cucumber/feature_file'
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
