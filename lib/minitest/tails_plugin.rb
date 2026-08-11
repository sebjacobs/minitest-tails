# frozen_string_literal: true

module Minitest
  def self.plugin_tails_init(_options)
    require_relative "tails" unless defined?(Tails::Reporter)
    return unless Tails.plugin_enabled?
    return if reporter.reporters.any? { |r| r.is_a?(Tails::Reporter) }

    reporter << Tails::Reporter.new
  end
end

# Minitest 6 dropped the automatic Gem.find_files plugin scan from its run, so a
# plugin is only picked up if it registers itself. Do that here; 5.x ignores the
# call (no register_plugin) and still auto-discovers this file the old way.
Minitest.register_plugin(:tails) if Minitest.respond_to?(:register_plugin)
