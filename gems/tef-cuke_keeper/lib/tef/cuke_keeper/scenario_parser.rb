# todo - Tempted to replace these parser classes with slightly extended CukeModeler models.

require 'text-table'

module TEF
  module CukeKeeper
    class CucumberScenarioParser
      def initialize(hash)
        @hash = hash
      end

      def name
        @hash[:name]
      end

      def line_no
        @hash[:line]
      end

      def tags
        @hash[:tags]
      end

      def tag_names
        tags.collect { |t| t[:name] }
      end

      def scenarios
        @hash[:elements].select { |ele| ele[:keyword] == 'Scenario' }
      end

      def raw_steps
        @hash[:steps]
      end

      def step_text
        res = ['Steps:']

        raw_steps.each do |raw_step|
          res << step_to_s(raw_step)
          res << example_table(raw_step[:rows]) if raw_step[:rows]
        end

        if @hash[:examples]
          res << 'Examples:'
          @hash[:examples].each do |example|
            res << example_table(example[:rows])
          end
        end

        res.join("\n")
      end

      def failed_step
        raw_steps.select { |step| step_failed?(step) }.first
      end

      def passed?
        failed_step.nil?
      end

      def error_message
        failed_step[:result][:error_message] unless failed_step.nil?
      end

      private

      def step_failed?(step_hash)
        return false unless step_hash[:result]
        return step_hash[:result][:status] == 'failed'
      end

      def step_to_s(raw_step)
        return "** #{raw_step[:keyword]}#{raw_step[:name]}   <-- Test failed on this step" if step_failed?(raw_step)
        "   #{raw_step[:keyword]}#{raw_step[:name]}"
      end

      def example_table(rows)
        table = Text::Table.new
        table.head = rows.first[:cells]
        rows[1..-1].each do |row|
          table.rows << row[:cells]
        end
        "        #{table.to_s.gsub("\n", "\n        ")}"
      end

    end
  end
end
