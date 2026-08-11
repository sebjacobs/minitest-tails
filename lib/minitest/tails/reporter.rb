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
      end

      def record(result)
        steps = Array(result.metadata[:story_steps])
        return if steps.empty?

        @io.puts
        @io.puts "#{feature(result)}: #{scenario(result)}"
        steps.each do |step|
          @io.puts if starts_a_phase?(step)
          @io.puts "  #{step}"
        end
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
