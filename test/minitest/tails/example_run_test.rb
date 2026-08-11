# frozen_string_literal: true

require "test_helper"
require "open3"

class ExampleRunTest < Minitest::Test
  ROOT = File.expand_path("../../..", __dir__)
  EXAMPLE = File.join(ROOT, "example", "treat_dispenser_feature_test.rb")

  def run_example(story:)
    Open3.capture2e({"STORY" => story}, RbConfig.ruby, "-I#{File.join(ROOT, "lib")}", EXAMPLE)
  end

  def test_the_reporter_narrates_the_steps_of_a_real_run
    output, status = run_example(story: "1")

    assert_predicate status, :success?, output
    assert_includes output, "Treat Dispenser: Dennis is served from a full hopper"
    assert_includes output, "Given a dispenser loaded with 100 treats"
    assert_includes output, "Then the hopper is down to 70"
  end

  def test_a_real_run_stays_quiet_without_STORY
    output, status = run_example(story: nil)

    assert_predicate status, :success?, output
    refute_includes output, "Given a dispenser loaded with 100 treats"
  end
end
