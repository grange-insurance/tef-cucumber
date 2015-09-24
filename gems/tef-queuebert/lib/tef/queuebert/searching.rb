require 'cuke_slicer'
# Feels like I shouldn't have to do this in a relative manner...
require 'tef/queuebert/gem_extensions'


module TEF
  module Queuebert
    module Searching

      def self.find_test_cases(root, target, filters = {})
        validate_target(target)
        filters = convert_filters(filters)

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

      def self.convert_filters(filters)
        filters = filters.dup

        [:included_paths, :excluded_paths, :included_tags, :excluded_tags].each do |filter_type|
          convert_filters_for(filter_type, filters)
        end

        filters
      end

      def self.convert_filters_for(filter_type, filters)
        if filters[filter_type]
          if filters[filter_type].is_a?(Array)
            filters[filter_type].collect! { |filter| converted_filter_for(filter) }
          else
            filters[filter_type] = converted_filter_for(filters[filter_type])
          end
        end
      end

      def self.converted_filter_for(filter)
        if filter.is_a?(String)
          filter.chop!.reverse!.chop!.reverse! if filter.match(/^\/.*\/$/)
          Regexp.new(Regexp.escape(filter))
        else
          filter
        end
      end

    end
  end
end
