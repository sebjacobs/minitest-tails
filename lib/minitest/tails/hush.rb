# frozen_string_literal: true

require "minitest"

module Minitest
  module Tails
    class Hush < AbstractReporter
      attr_reader :reporter

      def initialize(reporter)
        super()
        @reporter = reporter
      end

      def start = reporter.start

      def prerecord(klass, name)
        reporter.prerecord(klass, name) if reporter.respond_to?(:prerecord)
      end

      def record(result)
        io = reporter.io
        reporter.io = MarkerFilter.new(io)
        reporter.record(result)
      ensure
        reporter.io = io
      end

      def report = reporter.report
      def passed? = reporter.passed?
      def io = reporter.io

      def io=(io)
        reporter.io = io
      end

      def method_missing(name, ...) = reporter.public_send(name, ...)
      def respond_to_missing?(name, include_private = false) = reporter.respond_to?(name, include_private)

      class MarkerFilter
        MARKER = /\A[.FES]\z/
        ANSI_ESCAPE = /\e\[[\d;]*m/
        private_constant :MARKER, :ANSI_ESCAPE

        def initialize(io)
          @io = io
        end

        def print(*texts)
          kept = texts.reject { |text| marker?(text) }
          @io.print(*kept) unless kept.empty?
          nil
        end

        def write(*texts)
          texts.sum { |text| marker?(text) ? text.to_s.bytesize : @io.write(text) }
        end

        def <<(text)
          @io << text unless marker?(text)
          self
        end

        def method_missing(name, ...) = @io.public_send(name, ...)
        def respond_to_missing?(name, include_private = false) = @io.respond_to?(name, include_private)

        private

        def marker?(text) = MARKER.match?(text.to_s.gsub(ANSI_ESCAPE, ""))
      end
    end
  end
end
