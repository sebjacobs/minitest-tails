# frozen_string_literal: true

require "test_helper"
require "stringio"

class HushTest < Minitest::Test
  Result = Struct.new(:failure)

  class DotReporter < Minitest::Reporter
    attr_reader :prerecorded

    def initialize(io)
      super(io, {})
      @prerecorded = []
    end

    def prerecord(klass, name)
      @prerecorded << [klass, name]
    end

    def record(result)
      io.print("\e[31mF\e[0m")
      io.puts("bin/rails test test/hosts_search_test.rb:12") if result.failure
    end

    def report
      io.puts("Failed tests:")
    end

    def passed? = false
  end

  def hushed(io)
    reporter = DotReporter.new(io)
    [Minitest::Tails::Hush.new(reporter), reporter]
  end

  def test_swallows_the_progress_marker
    io = StringIO.new
    hush, _ = hushed(io)
    hush.record(Result.new(false))

    assert_empty io.string
  end

  def test_keeps_the_rest_of_what_the_reporter_prints_while_recording
    io = StringIO.new
    hush, _ = hushed(io)
    hush.record(Result.new(true))

    assert_equal "bin/rails test test/hosts_search_test.rb:12\n", io.string
  end

  def test_keeps_the_reporters_own_report
    io = StringIO.new
    hush, _ = hushed(io)
    hush.report

    assert_equal "Failed tests:\n", io.string
  end

  def test_hands_the_reporter_its_own_io_back_after_recording
    io = StringIO.new
    hush, reporter = hushed(io)
    hush.record(Result.new(false))

    assert_same io, reporter.io
  end

  def test_hands_the_io_back_even_when_recording_raises
    io = StringIO.new
    reporter = DotReporter.new(io)
    reporter.define_singleton_method(:record) { |_result| raise "boom" }
    hush = Minitest::Tails::Hush.new(reporter)

    assert_raises(RuntimeError) { hush.record(Result.new(false)) }
    assert_same io, reporter.io
  end

  def test_passes_prerecord_and_passed_through_to_the_reporter
    hush, reporter = hushed(StringIO.new)
    hush.prerecord("HostsSearchTest", "test_x")

    assert_equal [["HostsSearchTest", "test_x"]], reporter.prerecorded
    refute_predicate hush, :passed?
  end
end
