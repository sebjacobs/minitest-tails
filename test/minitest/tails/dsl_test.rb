# frozen_string_literal: true

require "test_helper"
require_relative "../../fixtures/shared_steps"

class DslTest < Minitest::Test
  def feature(&body)
    Class.new(Minitest::Test) do
      include Minitest::Tails

      class_exec(&body) if body
    end
  end

  def here = __FILE__.delete_prefix("#{Dir.pwd}/")

  def with_colour
    original = Minitest::Tails.palette
    Minitest::Tails.palette = Minitest::Tails::Palette.new(enabled: true)
    yield
  ensure
    Minitest::Tails.palette = original
  end

  def test_records_each_keyword_with_its_description
    test = feature.new("anon")
    test.given_("a precondition") {}
    test.when_("an action happens") {}
    test.then_("an outcome follows") {}
    test.and_("another holds") {}
    test.but_("not that one") {}

    steps = test.metadata[:story_steps]
    assert_equal %w[Given When Then And But], steps.map(&:keyword)
    assert_equal "a precondition", steps.first.description
    assert_equal "not that one", steps.last.description
  end

  def test_step_underscore_is_an_alias_for_step
    test = feature.new("anon")
    test.step_("Given a precondition") {}

    step = test.metadata[:story_steps].first
    assert_equal "Given", step.keyword
    assert_equal "a precondition", step.description
  end

  def test_a_step_that_runs_cleanly_is_marked_passed
    test = feature.new("anon")
    test.given_("a precondition") {}

    assert_equal :passed, test.metadata[:story_steps].first.status
  end

  def test_a_failing_step_is_marked_failed_and_earlier_steps_stay_passed
    test = feature.new("anon")
    test.given_("a precondition") {}
    assert_raises(Minitest::Assertion) do
      test.when_("an action fails") { raise Minitest::Assertion, "boom" }
    end

    given, when_step = test.metadata[:story_steps]
    assert_equal :passed, given.status
    assert_equal :failed, when_step.status
  end

  def test_a_failure_is_re_raised_with_the_narrative_prepended
    test = feature.new("anon")
    test.given_("a precondition") {}
    error = assert_raises(Minitest::Assertion) do
      test.when_("an action fails") { raise Minitest::Assertion, "boom" }
    end

    assert_includes error.message, "✓ Given a precondition"
    assert_includes error.message, "✗ When an action fails"
    assert_includes error.message, "boom"
  end

  def test_the_narrative_colours_its_marks_when_the_terminal_supports_it
    test = feature.new("anon")
    test.given_("a precondition") {}
    error = with_colour do
      assert_raises(Minitest::Assertion) do
        test.when_("an action fails") { raise Minitest::Assertion, "boom" }
      end
    end

    assert_includes error.message, "\e[32m✓\e[0m Given a precondition"
    assert_includes error.message, "\e[31m✗\e[0m When an action fails"
  end

  def test_a_standard_error_inside_a_step_is_also_captured
    test = feature.new("anon")
    error = assert_raises(RuntimeError) do
      test.given_("a broken precondition") { raise "kaboom" }
    end

    assert_equal :failed, test.metadata[:story_steps].first.status
    assert_includes error.message, "✗ Given a broken precondition"
  end

  def test_a_standard_error_narrates_under_a_rule_naming_the_scenario
    test = feature.new("anon")
    error = assert_raises(RuntimeError) do
      test.given_("a broken precondition") { raise "kaboom" }
    end

    assert_match(/\A\n── anon ─+\n\n  ✗ Given a broken precondition\n {6}\S+:\d+\n\nkaboom\z/, error.message)
  end

  def test_an_assertion_narrates_the_same_way_before_its_message
    test = feature.new("anon")
    error = assert_raises(Minitest::Assertion) do
      test.when_("an action fails") { raise Minitest::Assertion, "boom" }
    end

    assert_match(/\A\n── anon ─+\n\n  ✗ When an action fails\n {6}\S+:\d+\n\nboom\z/, error.message)
  end

  def test_a_failing_step_points_at_where_the_step_itself_was_written
    test = feature.new("anon")
    line = __LINE__ + 2
    error = assert_raises(Minitest::Assertion) do
      test.when_("an action fails") { raise Minitest::Assertion, "boom" }
    end

    assert_includes error.message, "✗ When an action fails\n      #{here}:#{line}"
  end

  def test_a_step_written_inside_a_helper_points_at_the_scenario_that_called_it
    scenario_line = __LINE__ + 5
    klass = feature do
      include SharedSteps

      scenario "a visitor does something" do
        when_an_action_fails
      end
    end
    result = klass.new("test_a_visitor_does_something").run

    assert_includes result.failures.first.message, "✗ When an action fails\n      #{here}:#{scenario_line}"
  end

  def test_a_step_reached_through_a_gem_still_points_at_the_scenario
    step_line = __LINE__ + 6
    klass = feature do
      include SharedSteps

      scenario "a visitor does something" do
        in_a_browser do
          when_("an action fails") { raise Minitest::Assertion, "boom" }
        end
      end
    end
    result = klass.new("test_a_visitor_does_something").run

    assert_includes result.failures.first.message, "✗ When an action fails\n      #{here}:#{step_line}"
  end

  def test_a_step_a_helper_writes_inside_a_wrapper_block_points_at_the_scenario
    step_line = __LINE__ + 6
    klass = feature do
      include SharedSteps

      scenario "a visitor does something" do
        in_a_browser do
          when_an_action_fails
        end
      end
    end
    result = klass.new("test_a_visitor_does_something").run

    assert_includes result.failures.first.message, "✗ When an action fails\n      #{here}:#{step_line}"
  end

  def test_a_passing_step_keeps_its_source_out_of_the_narrative
    test = feature.new("anon")
    test.given_("a precondition") {}
    error = assert_raises(Minitest::Assertion) do
      test.when_("an action fails") { raise Minitest::Assertion, "boom" }
    end

    assert_includes error.message, "✓ Given a precondition\n\n  ✗ When an action fails"
  end

  def test_scenario_defines_a_runnable_test_method
    klass = feature do
      scenario "a visitor does something" do
        given_("a precondition") {}
      end
    end

    assert_includes klass.runnable_methods, "test_a_visitor_does_something"
  end

  def test_a_scenario_runs_its_steps_when_invoked
    klass = feature do
      scenario "a visitor does something" do
        given_("a precondition") {}
        then_("it is recorded") {}
      end
    end
    test = klass.new("test_a_visitor_does_something")
    test.send(:test_a_visitor_does_something)

    assert_equal %w[Given Then], test.metadata[:story_steps].map(&:keyword)
  end

  def test_defining_the_same_scenario_twice_is_an_error
    assert_raises(ArgumentError) do
      feature do
        scenario("a visitor does something") {}
        scenario("a visitor does something") {}
      end
    end
  end
end
