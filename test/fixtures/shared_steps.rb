# frozen_string_literal: true

module SharedSteps
  def in_a_browser
    capture_io do
      yield
    end
  end

  def when_an_action_fails
    when_("an action fails") { raise Minitest::Assertion, "boom" }
  end
end
