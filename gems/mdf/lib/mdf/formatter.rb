require 'gherkin/formatter/json_formatter'
require 'singleton'

module MDF
  module Formatter
    class MetaDataFormatter < Gherkin::Formatter::JSONFormatter
      include Singleton

      attr_accessor :io

      def initialize()
        super($stdout)
      end

      def puts(data)
        output << data
      end

      def transition(data)
        transitions << data
      end

      def meta_data
        feature_element['meta_data'] ||= {}
      end

      private

      def output
        meta_data[:output] ||= []
      end

      def transitions
        meta_data['transitions'] ||= []
      end
    end
  end
end
