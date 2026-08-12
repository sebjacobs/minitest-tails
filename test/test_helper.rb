# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "minitest/tails"

require "minitest/autorun"

Minitest::Tails.palette = Minitest::Tails::Palette.new(enabled: false)
