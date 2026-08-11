# frozen_string_literal: true

require_relative "tails/version"
require_relative "tails/reporter"
require_relative "tails_plugin"

module Minitest
  module Tails
    PLUGIN_ENV_VARS = %w[TAILS STORY].freeze
    TRUTHY_STRINGS = %w[1 true].freeze
    private_constant :TRUTHY_STRINGS

    Step = Struct.new(:keyword, :description, :status)

    def self.plugin_enabled?
      PLUGIN_ENV_VARS.any? { |name| TRUTHY_STRINGS.include?(ENV[name]&.downcase) }
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
      step = Step.new(keyword:, description:, status: :running)
      story_steps << step
      yield if block_given?
      step.status = :passed
      nil
    rescue Minitest::Assertion, StandardError => failure
      step.status = :failed
      raise failure.class, "#{narrative}\n\n#{failure.message}", failure.backtrace
    end

    def narrative
      story_steps.map do |step|
        mark = case step.status
        when :passed then "✓"
        when :failed then "✗"
        else "•"
        end
        "  #{mark} #{step.keyword} #{step.description}"
      end.join("\n")
    end
  end
end
