# frozen_string_literal: true

require "test_helper"
require "stringio"

class ReporterTest < Minitest::Test
  Result = Struct.new(:klass, :name, :metadata)

  def report(klass:, name:, steps:)
    io = StringIO.new
    result = Result.new(klass, name, {story_steps: steps})
    Minitest::Tails::Reporter.new(io).record(result)
    io.string
  end

  def step(keyword, description)
    Minitest::Tails::Step.new(keyword:, description:, status: :passed)
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

    assert_includes output, "  Given a precondition"
    assert_includes output, "  Then an outcome"
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
end
