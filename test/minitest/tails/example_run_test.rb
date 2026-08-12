# frozen_string_literal: true

require "test_helper"
require "open3"

class ExampleRunTest < Minitest::Test
  ROOT = File.expand_path("../../..", __dir__)
  EXAMPLE = File.join(ROOT, "example", "treat_dispenser_feature_test.rb")

  LATE_DOTS = File.join(ROOT, "test", "fixtures", "late_dot_reporter_plugin.rb")

  def run_example(story:, plugins: [])
    requires = plugins.map { |path| "-r#{path}" }
    Open3.capture2e(
      {"STORY" => story},
      RbConfig.ruby,
      "-I#{File.join(ROOT, "lib")}",
      *requires,
      EXAMPLE
    )
  end

  def test_the_reporter_narrates_the_steps_of_a_real_run
    output, status = run_example(story: "1")

    assert_predicate status, :success?, output
    assert_includes output, "Treat Dispenser: Dennis is served from a full hopper"
    assert_includes output, "Given a dispenser loaded with 100 treats"
    assert_includes output, "Then the hopper is down to 70"
  end

  def test_no_dots_survive_from_a_reporter_another_plugin_adds
    output, status = run_example(story: "1", plugins: [LATE_DOTS])

    assert_predicate status, :success?, output
    assert_includes output, "Treat Dispenser: Dennis is served from a full hopper"
    refute_match(/^\.+$/, output)
  end

  def test_another_reporters_dots_are_left_alone_without_STORY
    output, status = run_example(story: nil, plugins: [LATE_DOTS])

    assert_predicate status, :success?, output
    assert_match(/^\.+$/, output)
  end

  def test_a_real_run_stays_quiet_without_STORY
    output, status = run_example(story: nil)

    assert_predicate status, :success?, output
    refute_includes output, "Given a dispenser loaded with 100 treats"
  end
end
