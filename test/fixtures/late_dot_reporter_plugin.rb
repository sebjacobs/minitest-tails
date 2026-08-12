# frozen_string_literal: true

require "minitest"

module Minitest
  class LateDotReporter < StatisticsReporter
    def record(result)
      super
      io.print(result.result_code)
    end
  end

  def self.plugin_late_dots_init(_options)
    reporter << LateDotReporter.new($stdout)
  end
end

if Minitest.respond_to?(:register_plugin)
  Minitest.register_plugin(:late_dots)
else
  Minitest.extensions << :late_dots
end
