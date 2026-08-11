# frozen_string_literal: true

# The `step` DSL surface — one lowercase method, the keyword carried as the
# first word of the prose. Compare with the given_/when_/then_ surface in
# treat_dispenser_feature_test.rb.
#
#   STORY=1 ruby -Ilib example/treat_dispenser_step_test.rb

require "minitest/autorun"
require "minitest/tails"

class TreatDispenser
  class HopperEmpty < StandardError; end

  attr_reader :hopper

  def initialize(hopper: 0)
    @hopper = hopper
  end

  def refill(amount)
    @hopper += amount
  end

  def dispense(amount)
    raise HopperEmpty if amount > @hopper
    @hopper -= amount
  end
end

class TreatDispenserStepTest < Minitest::Test
  include Minitest::Tails

  scenario "Dennis is served from a full hopper" do
    step "Given a dispenser loaded with 100 treats" do
      @dispenser = TreatDispenser.new(hopper: 100)
    end

    step "When Dennis triggers it for 30 of them" do
      @dispenser.dispense(30)
    end

    step "Then the hopper is down to 70" do
      assert_equal 70, @dispenser.hopper
    end
  end

  scenario "The dispenser will not serve more treats than it holds" do
    step_a_dispenser_loaded_with 50

    step "When Dennis begs it for 80" do
      @error = assert_raises(TreatDispenser::HopperEmpty) do
        @dispenser.dispense(80)
      end
    end

    step "Then the request is refused" do
      assert_instance_of TreatDispenser::HopperEmpty, @error
    end

    step "And the hopper still holds 50" do
      assert_equal 50, @dispenser.hopper
    end
  end

  private

  def step_a_dispenser_loaded_with(treats)
    step "Given a dispenser loaded with #{treats} treats" do
      @dispenser = TreatDispenser.new(hopper: treats)
    end
  end
end
