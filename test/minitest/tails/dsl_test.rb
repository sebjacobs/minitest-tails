# frozen_string_literal: true

require "test_helper"

class DslTest < Minitest::Test
  def feature(&body)
    Class.new(Minitest::Test) do
      include Minitest::Tails

      class_exec(&body) if body
    end
  end

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
