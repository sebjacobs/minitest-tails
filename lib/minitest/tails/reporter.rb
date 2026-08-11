# frozen_string_literal: true

require "minitest"

module Minitest
  module Tails
    class Reporter < Minitest::AbstractReporter
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
          @io.puts "  #{step.keyword} #{step.description}"
        end
      end

      private

      def feature(result)
        result.klass.sub(/(Feature)?Test\z/, "").gsub(/([a-z])([A-Z])/, '\1 \2')
      end

      def scenario(result)
        result.name.sub(/\Atest_/, "").tr("_", " ")
      end
    end
  end
end
