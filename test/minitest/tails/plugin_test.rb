# frozen_string_literal: true

require "test_helper"
require "minitest/tails_plugin"
require "stringio"

class PluginTest < Minitest::Test
  def setup
    @original_reporter = Minitest.reporter
    @original_env = Minitest::Tails::PLUGIN_ENV_VARS.to_h { |name| [name, ENV[name]] }
    Minitest::Tails::PLUGIN_ENV_VARS.each { |name| ENV.delete(name) }
    Minitest.reporter = Minitest::CompositeReporter.new
  end

  def teardown
    Minitest.reporter = @original_reporter
    @original_env.each { |name, value| ENV[name] = value }
  end

  def installed?
    Minitest.reporter.reporters.any? { |r| r.is_a?(Minitest::Tails::Reporter) }
  end

  def test_installs_the_story_reporter_when_TAILS_is_1
    ENV["TAILS"] = "1"
    Minitest.plugin_tails_init({})

    assert installed?
  end

  def test_installs_the_story_reporter_when_STORY_is_1
    ENV["STORY"] = "1"
    Minitest.plugin_tails_init({})

    assert installed?
  end

  def test_installs_the_story_reporter_when_either_variable_is_true_case_insensitively
    Minitest::Tails::PLUGIN_ENV_VARS.each do |name|
      Minitest.reporter = Minitest::CompositeReporter.new
      ENV[name] = "TRUE"
      Minitest.plugin_tails_init({})

      assert installed?, "expected #{name}=\"TRUE\" to install the reporter"
      ENV.delete(name)
    end
  end

  def test_installs_the_story_reporter_when_one_variable_is_truthy_and_the_other_is_not
    ENV["TAILS"] = "0"
    ENV["STORY"] = "1"
    Minitest.plugin_tails_init({})

    assert installed?
  end

  def test_drops_the_progress_reporter_so_the_dots_do_not_break_up_the_stories
    ENV["TAILS"] = "1"
    Minitest.reporter << Minitest::ProgressReporter.new(StringIO.new)
    Minitest.plugin_tails_init({})

    refute Minitest.reporter.reporters.any? { |r| r.is_a?(Minitest::ProgressReporter) }
  end

  def test_leaves_the_progress_reporter_alone_without_either_variable
    Minitest.reporter << Minitest::ProgressReporter.new(StringIO.new)
    Minitest.plugin_tails_init({})

    assert Minitest.reporter.reporters.any? { |r| r.is_a?(Minitest::ProgressReporter) }
  end

  def test_does_not_install_the_reporter_without_either_variable
    Minitest.plugin_tails_init({})

    refute installed?
  end

  def test_does_not_install_the_reporter_when_a_variable_is_blank_or_falsey
    Minitest::Tails::PLUGIN_ENV_VARS.each do |name|
      ["", "0", "false", "no"].each do |value|
        ENV[name] = value
        Minitest.plugin_tails_init({})

        refute installed?, "expected #{name}=#{value.inspect} to leave the reporter uninstalled"
      end
      ENV.delete(name)
    end
  end
end
