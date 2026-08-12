# frozen_string_literal: true

module Minitest
  module Tails
    class Palette
      ANSI_CODES = {green: 32, red: 31}.freeze
      private_constant :ANSI_CODES

      def self.for(io) = new(enabled: io.respond_to?(:tty?) && io.tty?)

      def initialize(enabled:)
        @enabled = enabled
      end

      def enabled? = @enabled

      def paint(text, colour)
        code = ANSI_CODES[colour]
        return text unless enabled? && code

        "\e[#{code}m#{text}\e[0m"
      end
    end
  end
end
