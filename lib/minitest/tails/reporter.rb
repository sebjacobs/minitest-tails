# frozen_string_literal: true

require "minitest"

module Minitest
  module Tails
    class Reporter < Minitest::AbstractReporter
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
        return if Array(result.metadata[:story_steps]).empty?

        story = Story.for(result)
        return if story.failed?

        @io.print("\n#{story.to_s(@palette)}\n")
      end
    end
  end
end
