# frozen_string_literal: true

require "test_helper"
require "stringio"

class ReporterTest < Minitest::Test
  Result = Struct.new(:klass, :name, :metadata)

  class RecordingIO
    attr_reader :writes

    def initialize = @writes = []

    def print(text) = writes << text
  end

  def report(klass:, name:, steps:)
    io = StringIO.new
    result = Result.new(klass, name, {story_steps: steps})
    Minitest::Tails::Reporter.new(io).record(result)
    io.string
  end

  def step(keyword, description, status = :passed)
    Minitest::Tails::Step.new(keyword:, description:, status:)
  end

  def test_prints_the_feature_and_scenario_heading
    output = report(
      klass: "HostsSearchFeatureTest",
      name: "test_a_visitor_searches_nearby",
      steps: [step("Given", "a precondition")]
    )

    assert_includes output, "Hosts Search: a visitor searches nearby"
  end

  def test_prints_each_step_with_its_keyword_and_description
    output = report(
      klass: "WidgetTest",
      name: "test_it_works",
      steps: [step("Given", "a precondition"), step("Then", "an outcome")]
    )

    assert_includes output, "  ✓ Given a precondition"
    assert_includes output, "  ✓ Then an outcome"
  end

  def test_marks_a_failed_step_and_leaves_earlier_ones_passed
    output = report(
      klass: "WidgetTest",
      name: "test_it_works",
      steps: [step("Given", "a precondition"), step("When", "it breaks", :failed)]
    )

    assert_includes output, "  ✓ Given a precondition"
    assert_includes output, "  ✗ When it breaks"
  end

  def test_separates_each_phase_with_a_blank_line
    output = report(
      klass: "WidgetTest",
      name: "test_it_works",
      steps: [step("Given", "a precondition"), step("When", "an action happens")]
    )

    assert_includes output, "  ✓ Given a precondition\n\n  ✓ When an action happens\n"
  end

  def test_keeps_a_continuation_attached_to_the_step_it_follows
    output = report(
      klass: "WidgetTest",
      name: "test_it_works",
      steps: [step("Then", "an outcome"), step("And", "another holds"), step("But", "not that one")]
    )

    assert_includes output, "  ✓ Then an outcome\n  ✓ And another holds\n  ✓ But not that one\n"
  end

  def test_treats_a_lowercase_continuation_keyword_as_a_continuation
    output = report(
      klass: "WidgetTest",
      name: "test_it_works",
      steps: [step("then", "an outcome"), step("and", "another holds")]
    )

    assert_includes output, "  ✓ then an outcome\n  ✓ and another holds\n"
  end

  def test_prints_nothing_for_a_result_without_story_steps
    io = StringIO.new
    result = Result.new("WidgetTest", "test_it_works", {})
    Minitest::Tails::Reporter.new(io).record(result)

    assert_empty io.string
  end

  def test_derives_a_plain_feature_name_without_feature_suffix
    output = report(klass: "WidgetTest", name: "test_x", steps: [step("Given", "y")])

    assert_includes output, "Widget: x"
  end

  def test_names_the_feature_after_the_class_alone_not_its_namespace
    output = report(klass: "Kennel::WalkiesTest", name: "test_x", steps: [step("Given", "y")])

    assert_includes output, "Walkies: x"
  end

  def test_writes_a_scenario_in_a_single_call_so_parallel_runs_cannot_interleave
    io = RecordingIO.new
    result = Result.new("WidgetTest", "test_it_works", {story_steps: [step("Given", "y")]})
    Minitest::Tails::Reporter.new(io).record(result)

    assert_equal ["\nWidget: it works\n\n  ✓ Given y\n"], io.writes
  end

  def test_keeps_an_acronym_whole_when_splitting_the_feature_name
    output = report(klass: "GPSCollarTest", name: "test_x", steps: [step("Given", "y")])

    assert_includes output, "GPS Collar: x"
  end
end
