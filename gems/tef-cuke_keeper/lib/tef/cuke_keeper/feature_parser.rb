require_relative 'scenario_parser'

module TEF
  module CukeKeeper
    class CucumberFeatureParser
      def initialize(hash)
        @hash = hash
      end

      def name
        @hash[:name]
      end

      def tags
        @hash[:tags]
      end

      def tag_names
        tags.collect { |t| t[:name] }
      end

      def path
        @hash[:uri]
      end

      def scenarios()
        @hash[:elements].select { |ele| ele[:keyword] == 'Scenario' || ele[:keyword] == 'Scenario Outline'}.collect { |scen| CucumberScenarioParser.new(scen) }
      end

    end
  end
end
