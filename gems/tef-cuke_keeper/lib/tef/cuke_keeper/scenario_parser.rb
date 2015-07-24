# todo - Tempted to replace these parser classes with slightly extended CukeModeler models.

require 'text-table'

module TEF
  module CukeKeeper
    class CucumberScenarioParser
      def initialize(hash)
        @hash = hash
      end

      def scenario?
        @hash[:type] == 'scenario'
      end

      def outline?
        @hash[:type] == 'scenario_outline'
      end

      def name
        @hash[:name]
      end

      def line_no
        @hash[:line]
      end

      def row_no
        @hash[:row_line]
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

      def steps
        String.new.tap do |steps|
          raw_steps.each do |raw_step|
            steps << "#{raw_step[:keyword]}#{raw_step[:name]}\n"
          end

          steps.chomp!
        end
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

      def status
        case
          when raw_steps.all? { |step| step_passed?(step) }
            return 'pass'
          when raw_steps.any? { |step| step_failed?(step) }
            return 'fail'
          when raw_steps.any? { |step| step_pending?(step) }
            return 'pending'
          when raw_steps.any? { |step| step_undefined?(step) }
            return 'undefined'
          else
            raise("Can't determine the status of the test result.")
        end
      end

      def passed?
        failed_step.nil?
      end

      def error_message
        failed_step[:result][:error_message] unless failed_step.nil?
      end

      def runtime
        raw_steps.reduce(0) { |total, step| total += (step[:result][:duration] / 1000000000.0) }
      end


      private


      def step_failed?(step_hash)
        return false unless step_hash[:result]
        return step_hash[:result][:status] == 'failed'
      end

      def step_passed?(step_hash)
        return false unless step_hash[:result]
        return step_hash[:result][:status] == 'passed'
      end

      def step_skipped?(step_hash)
        return false unless step_hash[:result]
        return step_hash[:result][:status] == 'skipped'
      end

      def step_pending?(step_hash)
        return false unless step_hash[:result]
        return step_hash[:result][:status] == 'pending'
      end

      def step_undefined?(step_hash)
        return false unless step_hash[:result]
        return step_hash[:result][:status] == 'undefined'
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
