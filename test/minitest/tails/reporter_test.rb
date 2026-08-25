# frozen_string_literal: true

require "test_helper"
require "stringio"

class ReporterTest < Minitest::Test
  Result = Struct.new(:klass, :name, :metadata)

  class RecordingIO
    attr_reader :writes

    def initialize(tty: false)
      @writes = []
      @tty = tty
    end

    def tty? = @tty

    def print(text) = writes << text
  end

  def report(klass:, name:, steps:)
    io = StringIO.new
    result = Result.new(klass, name, {story_steps: steps})
    Minitest::Tails::Reporter.new(io).record(result)
    io.string
  end

  def step(keyword, description, status = :passed, source: nil)
    Minitest::Tails::Step.new(keyword:, description:, status:, source:)
  end

  def test_prints_a_scenario_that_passed
    output = report(
      klass: "HostsSearchFeatureTest",
      name: "test_a_visitor_searches_nearby",
      steps: [step("Given", "a precondition"), step("Then", "an outcome")]
    )

    assert_includes output, "── Hosts Search: a visitor searches nearby ─"
    assert_includes output, "  ✓ Given a precondition"
    assert_includes output, "  ✓ Then an outcome"
  end

  def test_leaves_a_failed_scenario_to_the_failure_that_already_narrates_it
    output = report(
      klass: "WidgetTest",
      name: "test_it_works",
      steps: [step("Given", "a precondition"), step("When", "it breaks", :failed)]
    )

    assert_empty output
  end

  def test_prints_nothing_for_a_result_without_story_steps
    io = StringIO.new
    result = Result.new("WidgetTest", "test_it_works", {})
    Minitest::Tails::Reporter.new(io).record(result)

    assert_empty io.string
  end

  def test_writes_a_scenario_in_a_single_call_so_parallel_runs_cannot_interleave
    io = RecordingIO.new
    result = Result.new("WidgetTest", "test_it_works", {story_steps: [step("Given", "y")]})
    Minitest::Tails::Reporter.new(io).record(result)

    assert_equal 1, io.writes.size
    assert_match(/\A\n── Widget: it works ─+\n\n  ✓ Given y\n\z/, io.writes.first)
  end

  def test_paints_the_marks_when_the_output_is_a_terminal
    io = RecordingIO.new(tty: true)
    result = Result.new("WidgetTest", "test_it_works", {story_steps: [step("Given", "a precondition")]})
    Minitest::Tails::Reporter.new(io).record(result)

    assert_includes io.writes.join, "  \e[32m✓\e[0m Given a precondition"
  end

  def test_leaves_the_marks_uncoloured_when_the_output_is_not_a_terminal
    io = RecordingIO.new(tty: false)
    result = Result.new("WidgetTest", "test_it_works", {story_steps: [step("Given", "y")]})
    Minitest::Tails::Reporter.new(io).record(result)

    refute_includes io.writes.join, "\e["
  end

  def composite_with(*reporters)
    composite = Minitest::CompositeReporter.new(*reporters)
    composite << Minitest::Tails::Reporter.new(StringIO.new, composite:)
    composite
  end

  def test_hushes_a_sibling_reporter_when_the_run_starts
    progress = Minitest::ProgressReporter.new(StringIO.new)
    composite = composite_with(progress)
    composite.start

    assert_equal [progress], composite.reporters.grep(Minitest::Tails::Hush).map(&:reporter)
  end

  def test_leaves_the_summary_reporter_alone_so_minitest_can_still_find_it
    summary = Minitest::SummaryReporter.new(StringIO.new)
    composite = composite_with(summary)
    composite.start

    assert_equal [summary], composite.reporters.grep(Minitest::SummaryReporter)
  end

  def test_leaves_the_story_reporter_itself_unhushed
    composite = composite_with
    composite.start

    assert_equal 1, composite.reporters.grep(Minitest::Tails::Reporter).size
  end

  def test_hushes_a_sibling_only_once_however_often_the_run_starts
    composite = composite_with(Minitest::ProgressReporter.new(StringIO.new))
    2.times { composite.start }

    hushed = composite.reporters.grep(Minitest::Tails::Hush)
    assert_equal 1, hushed.size
    refute_kind_of Minitest::Tails::Hush, hushed.first.reporter
  end

  def test_starting_without_a_composite_is_harmless
    assert_nil Minitest::Tails::Reporter.new(StringIO.new).start
  end

  def test_keeps_an_acronym_whole_when_splitting_the_feature_name
    output = report(klass: "GPSCollarTest", name: "test_x", steps: [step("Given", "y")])

    assert_includes output, "GPS Collar: x"
  end
end
