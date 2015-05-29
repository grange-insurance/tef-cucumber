require_relative 'feature_parser'
require 'json'

module TEF
  module CukeKeeper
    class CucumberJsonParser
      attr_reader :results

      def initialize(json_data)
        @results = json_data.class == Hash ? json_data : JSON.parse(json_data, symbolize_names: true)
      end

      def features
        @results.select { |ele| ele[:keyword] == 'Feature' }.collect { |feat| CucumberFeatureParser.new(feat) }
      end
    end
  end
end

