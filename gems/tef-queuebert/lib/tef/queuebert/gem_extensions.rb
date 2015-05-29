module CukeModeler
  module Parsing

    class << self
      alias_method :original_parse_text, :parse_text

      # Monkey patching how parsing works so that it won't explode on a bad file
      def parse_text(source_text)
        begin
          original_parse_text(source_text)
        rescue
          # Try again with an empty file so that we can keep moving
          original_parse_text('')
        end
      end
    end

  end
end
