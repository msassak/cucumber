module Cucumber
  class Resource
    SCHEME_PATH_LINES_PATTERN = /([\w\W]+:\/\/)?([\w\W]+?)(:[\d:]+)?$/ #:nodoc:

    attr_reader :protocol, :format, :path, :lines

    def initialize(resource)
      _, scheme, @path, lines = *SCHEME_PATH_LINES_PATTERN.match(resource)
      @protocol, @format = extract_protocol_and_format(scheme)
      @lines = extract_lines(lines)
    end

    def path
      if protocol == :file
        @path
      else
        "#{protocol}://#{@path}"
      end
    end

    private

    def extract_protocol_and_format(scheme)
      proto = fmt = nil

      if scheme
        scheme = scheme.chomp('://')
        proto, fmt = scheme.split('+').collect{|part| part.to_sym}
      end

      [proto || :file, fmt || :gherkin]
    end

    def extract_lines(lines)
      lines ? lines.split(':')[1..-1].map{|n| n.to_i} : nil
    end
  end
end
