# frozen_string_literal: true

require_relative "tails/version"
require_relative "tails/palette"
require_relative "tails/hush"
require_relative "tails/story"
require_relative "tails/reporter"
require_relative "tails_plugin"

module Minitest
  module Tails
    PLUGIN_ENV_VARS = %w[TAILS STORY].freeze
    TRUTHY_STRINGS = %w[1 true].freeze
    private_constant :TRUTHY_STRINGS

    STEP_MARKS = {passed: "✓", failed: "✗"}.freeze
    private_constant :STEP_MARKS

    STEP_COLOURS = {passed: :green, failed: :red}.freeze
    private_constant :STEP_COLOURS

    GEM_ROOTS = ([Gem.dir] + Gem.path).compact.uniq.map { |root| "#{root}/" }.freeze
    private_constant :GEM_ROOTS

    def self.palette = @palette ||= Palette.for($stdout)

    class << self
      attr_writer :palette
    end

    Step = Struct.new(:keyword, :description, :status, :source) do
      def to_s(palette = Tails.palette) = "#{mark(palette)} #{keyword} #{description}"

      def to_lines(palette = Tails.palette)
        return [to_s(palette)] unless status == :failed && source

        [to_s(palette), "    #{source}"]
      end

      private

      def mark(palette)
        palette.paint(STEP_MARKS.fetch(status, "•"), STEP_COLOURS[status])
      end
    end

    def self.plugin_enabled?
      PLUGIN_ENV_VARS.any? { |name| TRUTHY_STRINGS.include?(ENV[name]&.downcase) }
    end

    def self.hush_others(composite)
      return unless composite.respond_to?(:reporters) && composite.respond_to?(:reporters=)

      composite.reporters = composite.reporters.map { |r| hushable?(r) ? Hush.new(r) : r }
    end

    def self.hushable?(reporter)
      return false if reporter.is_a?(Reporter) || reporter.is_a?(Hush)
      return false if reporter.is_a?(Minitest::SummaryReporter)

      reporter.respond_to?(:io) && reporter.respond_to?(:io=)
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def scenario(name, &block)
        method_name = "test_#{name.strip.gsub(/\s+/, "_")}"
        raise ArgumentError, "scenario already defined: #{name}" if method_defined?(method_name)
        define_method(method_name, &block)
      end
    end

    def story_steps
      metadata[:story_steps] ||= []
    end

    def step(text, &block)
      keyword, _, description = text.partition(" ")
      run_step(keyword, description, &block)
    end

    alias_method :step_, :step

    def given_(description, &block) = run_step("Given", description, &block)
    def when_(description, &block) = run_step("When", description, &block)
    def then_(description, &block) = run_step("Then", description, &block)
    def and_(description, &block) = run_step("And", description, &block)
    def but_(description, &block) = run_step("But", description, &block)

    private

    def run_step(keyword, description)
      step = Step.new(keyword:, description:, status: :running, source: step_source)
      story_steps << step
      yield if block_given?
      step.status = :passed
      nil
    rescue Minitest::Assertion, StandardError => failure
      step.status = :failed
      raise failure.class, "\n#{narrative}\n\n#{failure.message}", failure.backtrace
    end

    def step_source
      frames = caller_locations(1)&.reject { |frame| frame.path == __FILE__ }
      return if frames.nil? || frames.empty?

      frame = outermost_frame_of_your_own(frames) || frames.first
      "#{relative_to_working_directory(frame.path)}:#{frame.lineno}"
    end

    def outermost_frame_of_your_own(frames)
      frames.take_while { |frame| your_own?(frame) }.last
    end

    def your_own?(frame)
      path = frame.absolute_path || frame.path
      path.start_with?(working_directory) && GEM_ROOTS.none? { |root| path.start_with?(root) }
    end

    def relative_to_working_directory(path)
      path.start_with?(working_directory) ? path.delete_prefix(working_directory) : path
    end

    def working_directory = "#{Dir.pwd}/"

    def narrative
      Story.new(klass_name: self.class.name, test_name: name, steps: story_steps).to_s
    end
  end
end
