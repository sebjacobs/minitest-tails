# frozen_string_literal: true

# A self-contained, runnable example of minitest/tails, starring Dennis —
# a smooth red miniature dachshund with strong views on treats.
#
# Run it with the narrative reporter:
#
#   STORY=1 ruby -Ilib example/treat_dispenser_feature_test.rb
#
# Run it normally (no story output) by omitting STORY.

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

class TreatDispenserFeatureTest < Minitest::Test
  include Minitest::Tails

  scenario "Dennis is served from a full hopper" do
    given_ "a dispenser loaded with 100 treats" do
      @dispenser = TreatDispenser.new(hopper: 100)
    end

    when_ "Dennis triggers it for 30 of them" do
      @dispenser.dispense(30)
    end

    then_ "the hopper is down to 70" do
      assert_equal 70, @dispenser.hopper
    end
  end

  scenario "The dispenser will not serve more treats than it holds" do
    given_a_dispenser_loaded_with 50

    when_ "Dennis begs it for 80" do
      @error = assert_raises(TreatDispenser::HopperEmpty) do
        @dispenser.dispense(80)
      end
    end

    then_ "the request is refused" do
      assert_instance_of TreatDispenser::HopperEmpty, @error
    end

    and_ "the hopper still holds 50" do
      assert_equal 50, @dispenser.hopper
    end
  end

  private

  def given_a_dispenser_loaded_with(treats)
    given_ "a dispenser loaded with #{treats} treats" do
      @dispenser = TreatDispenser.new(hopper: treats)
    end
  end
end
