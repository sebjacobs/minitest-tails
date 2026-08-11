# frozen_string_literal: true

require_relative "tails"

module Minitest
  def self.plugin_tails_init(_options)
    reporter << Tails::Reporter.new if ENV["STORY"]
  end
end
