# frozen_string_literal: true

require "test_helper"
require "minitest/tails_plugin"

class PluginTest < Minitest::Test
  def setup
    @original_reporter = Minitest.reporter
    @original_story = ENV["STORY"]
    Minitest.reporter = Minitest::CompositeReporter.new
  end

  def teardown
    Minitest.reporter = @original_reporter
    ENV["STORY"] = @original_story
  end

  def installed?
    Minitest.reporter.reporters.any? { |r| r.is_a?(Minitest::Tails::Reporter) }
  end

  def test_installs_the_story_reporter_when_STORY_is_set
    ENV["STORY"] = "1"
    Minitest.plugin_tails_init({})

    assert installed?
  end

  def test_does_not_install_the_reporter_without_STORY
    ENV.delete("STORY")
    Minitest.plugin_tails_init({})

    refute installed?
  end
end
