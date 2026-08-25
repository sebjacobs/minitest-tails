# frozen_string_literal: true

require "test_helper"

class StoryTest < Minitest::Test
  def story(klass_name: "WidgetTest", test_name: "test_it_works", steps: [])
    Minitest::Tails::Story.new(klass_name:, test_name:, steps:)
  end

  def step(keyword, description, status = :passed, source: nil)
    Minitest::Tails::Step.new(keyword:, description:, status:, source:)
  end

  def plain = Minitest::Tails::Palette.new(enabled: false)

  def coloured = Minitest::Tails::Palette.new(enabled: true)

  def test_opens_on_a_rule_naming_the_feature_and_the_scenario
    heading = story(klass_name: "HostsSearchFeatureTest", test_name: "test_a_visitor_searches_nearby")
      .to_lines(plain).first

    assert_match(/\A── Hosts Search: a visitor searches nearby ─+\z/, heading)
  end

  def test_rules_out_to_a_fixed_width_so_stories_line_up
    widths = [
      story(test_name: "test_x").to_lines(plain).first,
      story(test_name: "test_a_much_longer_scenario_name").to_lines(plain).first
    ].map(&:length)

    assert_equal widths.first, widths.last
  end

  def test_drops_the_feature_from_the_heading_when_the_class_is_anonymous
    assert_match(/\A── it works ─+\z/, story(klass_name: nil).to_lines(plain).first)
  end

  def test_prints_each_step_with_its_keyword_and_description
    output = story(steps: [step("Given", "a precondition"), step("Then", "an outcome")]).to_s(plain)

    assert_includes output, "  ✓ Given a precondition"
    assert_includes output, "  ✓ Then an outcome"
  end

  def test_separates_each_phase_with_a_blank_line
    output = story(steps: [step("Given", "a precondition"), step("When", "an action happens")]).to_s(plain)

    assert_includes output, "  ✓ Given a precondition\n\n  ✓ When an action happens"
  end

  def test_keeps_a_continuation_attached_to_the_step_it_follows
    steps = [step("Then", "an outcome"), step("And", "another holds"), step("But", "not that one")]

    assert_includes story(steps:).to_s(plain),
      "  ✓ Then an outcome\n  ✓ And another holds\n  ✓ But not that one"
  end

  def test_treats_a_lowercase_continuation_keyword_as_a_continuation
    steps = [step("then", "an outcome"), step("and", "another holds")]

    assert_includes story(steps:).to_s(plain), "  ✓ then an outcome\n  ✓ and another holds"
  end

  def test_prints_the_source_of_a_failed_step_beneath_it
    steps = [step("When", "it breaks", :failed, source: "test/widget_test.rb:12")]

    assert_includes story(steps:).to_s(plain), "  ✗ When it breaks\n      test/widget_test.rb:12"
  end

  def test_leaves_the_source_of_a_passing_step_unprinted
    steps = [step("Given", "a precondition", source: "test/widget_test.rb:9")]

    refute_includes story(steps:).to_s(plain), "test/widget_test.rb:9"
  end

  def test_knows_it_failed_when_any_step_did
    steps = [step("Given", "a precondition"), step("When", "it breaks", :failed)]

    assert_predicate story(steps:), :failed?
    refute_predicate story(steps: steps.take(1)), :failed?
  end

  def test_marks_a_passed_step_green_and_a_failed_one_red
    steps = [step("Given", "a precondition"), step("When", "it breaks", :failed)]
    output = story(steps:).to_s(coloured)

    assert_includes output, "  \e[32m✓\e[0m Given a precondition"
    assert_includes output, "  \e[31m✗\e[0m When it breaks"
  end

  def test_derives_a_plain_feature_name_without_feature_suffix
    assert_includes story(klass_name: "WidgetTest", test_name: "test_x").to_s(plain), "Widget: x"
  end

  def test_names_the_feature_after_the_class_alone_not_its_namespace
    assert_includes story(klass_name: "Kennel::WalkiesTest", test_name: "test_x").to_s(plain), "Walkies: x"
  end
end
