module CukeModeler
  module Parsing

    class << self

      # Adding some logging capability so that we can have better feedback
      def set_logger(new_logger)
        @logger = new_logger
      end

      def logger
        @logger
      end


      # Monkey patching how parsing works so that it won't explode on a bad file
      alias_method :original_parse_text, :parse_text

      def parse_text(source_text, file_name)
        begin
          original_parse_text(source_text, file_name)
        rescue
          logger.warn("Could not parse file: #{file_name}")

          # Try again with an empty file so that we can keep moving
          original_parse_text('', file_name)
        end
      end

    end

  end
end
