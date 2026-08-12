# frozen_string_literal: true

require "minitest"

module Minitest
  module Tails
    class Reporter < Minitest::AbstractReporter
      CONTINUATION_KEYWORDS = %w[and but].freeze
      private_constant :CONTINUATION_KEYWORDS

      def initialize(io = $stdout)
        super()
        @io = io
        @palette = Palette.for(io)
      end

      def record(result)
        steps = Array(result.metadata[:story_steps])
        return if steps.empty?

        lines = ["", "#{feature(result)}: #{scenario(result)}"]
        steps.each do |step|
          lines << "" if starts_a_phase?(step)
          lines << "  #{step.to_s(@palette)}"
        end
        @io.print("#{lines.join("\n")}\n")
      end

      private

      def starts_a_phase?(step)
        !CONTINUATION_KEYWORDS.include?(step.keyword.downcase)
      end

      def feature(result)
        result.klass.split("::").last
          .sub(/(Feature)?Test\z/, "")
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1 \2')
          .gsub(/([a-z\d])([A-Z])/, '\1 \2')
      end

      def scenario(result)
        result.name.sub(/\Atest_/, "").tr("_", " ")
      end
    end
  end
end
