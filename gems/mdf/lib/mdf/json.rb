require 'cucumber/formatter/gherkin_formatter_adapter'
require 'cucumber/formatter/io'
require 'gherkin/formatter/argument'
require 'mdf/formatter'

module MDF
  module Formatter
    class Json <  Cucumber::Formatter::GherkinFormatterAdapter
      include Cucumber::Formatter::Io

      def initialize(step_mother, io, options)
        @io = ensure_io(io, 'meta_json')
        MDF::Formatter::MetaDataFormatter.instance.io = io
        super(MDF::Formatter::MetaDataFormatter.instance, false)
      end
    end
  end
end
