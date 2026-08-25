# frozen_string_literal: true

module Minitest
  module Tails
    class Story
      CONTINUATION_KEYWORDS = %w[and but].freeze
      private_constant :CONTINUATION_KEYWORDS

      RULE = "─"
      RULE_WIDTH = 72
      private_constant :RULE, :RULE_WIDTH

      def self.for(result)
        new(klass_name: result.klass, test_name: result.name, steps: Array(result.metadata[:story_steps]))
      end

      def initialize(klass_name:, test_name:, steps:)
        @klass_name = klass_name.to_s
        @test_name = test_name.to_s
        @steps = steps
      end

      def failed? = @steps.any? { |step| step.status == :failed }

      def to_lines(palette = Tails.palette) = [heading, *step_lines(palette)]

      def to_s(palette = Tails.palette) = to_lines(palette).join("\n")

      private

      def heading = "#{RULE * 2} #{title} ".ljust(RULE_WIDTH, RULE)

      def title = [feature, scenario].reject(&:empty?).join(": ")

      def step_lines(palette)
        @steps.flat_map do |step|
          marked = step.to_lines(palette).map { |line| "  #{line}" }
          starts_a_phase?(step) ? ["", *marked] : marked
        end
      end

      def starts_a_phase?(step)
        !CONTINUATION_KEYWORDS.include?(step.keyword.downcase)
      end

      def feature
        @klass_name.split("::").last.to_s
          .sub(/(Feature)?Test\z/, "")
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1 \2')
          .gsub(/([a-z\d])([A-Z])/, '\1 \2')
      end

      def scenario = @test_name.sub(/\Atest_/, "").tr("_", " ")
    end
  end
end
