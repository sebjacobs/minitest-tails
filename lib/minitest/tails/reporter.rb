# frozen_string_literal: true

require "minitest"

module Minitest
  module Tails
    class Reporter < Minitest::AbstractReporter
      CONTINUATION_KEYWORDS = %w[and but].freeze
      private_constant :CONTINUATION_KEYWORDS

      # The composite is handed over at init because Minitest sets Minitest.reporter
      # back to nil before it starts the run, so #start cannot look it up itself.
      def initialize(io = $stdout, composite: nil)
        super()
        @io = io
        @composite = composite
        @palette = Palette.for(io)
      end

      def start
        Tails.hush_others(@composite)
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
