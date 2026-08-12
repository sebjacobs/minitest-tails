# frozen_string_literal: true

require "test_helper"
require "stringio"

class PaletteTest < Minitest::Test
  Palette = Minitest::Tails::Palette

  def test_wraps_the_text_in_the_ansi_code_for_the_colour
    palette = Palette.new(enabled: true)

    assert_equal "\e[32m✓\e[0m", palette.paint("✓", :green)
    assert_equal "\e[31m✗\e[0m", palette.paint("✗", :red)
  end

  def test_leaves_the_text_alone_when_disabled
    assert_equal "✓", Palette.new(enabled: false).paint("✓", :green)
  end

  def test_leaves_the_text_alone_for_a_colour_it_does_not_know
    assert_equal "•", Palette.new(enabled: true).paint("•", nil)
  end

  def test_is_enabled_for_a_terminal_and_disabled_for_anything_else
    refute_predicate Palette.for(StringIO.new), :enabled?
    refute_predicate Palette.for(Object.new), :enabled?
    assert_predicate Palette.for(tty), :enabled?
  end

  def tty
    io = StringIO.new
    def io.tty? = true
    io
  end
end
