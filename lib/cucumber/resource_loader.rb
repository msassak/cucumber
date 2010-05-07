require 'cucumber/feature_file'
require 'cucumber/formatter/duration'

module Cucumber
  class ResourceLoader
    include Formatter::Duration
    attr_accessor :log, :options

    def load_resources(feature_files)
      features = Ast::Features.new

      start = Time.new
      log.debug("Features:\n")
      feature_files.each do |f|
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
