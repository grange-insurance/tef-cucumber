require 'cuke_slicer'
# Feels like I shouldn't have to do this in a relative manner...
require_relative 'gem_extensions'


module TEF
  module Queuebert
    module Searching

      def self.find_test_cases(root, target, filters = {})
        validate_target(target)

        target = [target] if target.is_a?(String)

        test_cases = Array.new.tap do |found_tests|
          target.each do |directory|
            found_tests.concat(CukeSlicer::Slicer.new.slice("#{root}/#{directory}", filters))
          end
        end

        test_cases.map { |test_case| test_case.sub("#{root}/", '') }
      end

      def self.known_filters
        [:excluded_tags,
         :included_tags,
         :excluded_paths,
         :included_paths]
      end


      private


      def self.validate_target(target)
        raise(ArgumentError, "Search target must be a String or Array. Got #{target.class}") unless target.is_a?(String) || target.is_a?(Array)
      end

    end
  end
end
