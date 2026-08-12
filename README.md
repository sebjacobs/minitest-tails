# minitest-tails

> Every test tells a tail.

A small Gherkin-style story DSL for [Minitest](https://github.com/minitest/minitest).

Write your tests as `given_`/`when_`/`then_` scenarios. Each step is recorded as it
runs, so when an assertion fails the narrative is prepended to the failure
message — you see the story up to and including the step that broke. An optional
reporter prints passing scenarios as readable stories too.

```
Treat Dispenser: The dispenser will not serve more treats than it holds
  ✓ Given a dispenser loaded with 50 treats
  ✗ When Dennis begs it for 80

Expected a HopperEmpty to be raised but nothing was raised.
```

## Installation

Add it to your Gemfile's test group:

```ruby
gem "minitest-tails"
```

Then `bundle install`.

## Usage

`include Minitest::Tails` in a test class to get the `scenario` macro and the
`given_`/`when_`/`then_`/`and_`/`but_` step methods:

```ruby
require "minitest/autorun"
require "minitest/tails"

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
end
```

The trailing underscore keeps every keyword uniform: `when`, `then` and `and`
are Ruby keywords that can't be called bare, so all five methods carry the
underscore rather than only the ones that need it.

A step is just a labelled block. The block runs immediately; if it raises (an
assertion failure or any other error), the step is marked failed and the
collected narrative is prepended to the error message before it is re-raised.

Prefer the keyword in the prose? `step "Given a dispenser loaded with 100 treats" do … end`
does the same thing, taking the leading word as the keyword. `step_` is an alias,
for anyone who wants the underscore on every step method.

### Reusable steps

Wrap a step in a private helper to share it across scenarios — the keyword call
still happens inside the helper, so it appears in the narrative:

```ruby
private

def given_a_dispenser_loaded_with(treats)
  given_ "a dispenser loaded with #{treats} treats" do
    @dispenser = TreatDispenser.new(hopper: treats)
  end
end
```

### The story reporter

Set `TAILS=1` (or `TAILS=true`, case-insensitive) to attach the narrative
reporter, which prints each scenario's steps as it runs:

```bash
TAILS=1 rake test
```

`STORY` is accepted as an equivalent, so either name switches the reporter on.

```
Treat Dispenser: The dispenser will not serve more treats than it holds

  ✓ Given a dispenser loaded with 50 treats

  ✓ When Dennis begs it for 80

  ✓ Then the request is refused
  ✓ And the hopper still holds 50
```

Each phase is separated by a blank line; `And` and `But` stay attached to the
step they continue. Every step carries the same ✓/✗ mark it has in a failure
narrative — green when it passed, red when it broke, and uncoloured when the
output is not a terminal. While the reporter is attached it takes the place of the
progress dots, which say nothing the stories don't — whichever reporter is
printing them. Everything else those reporters print, including the summary and
failure output, is untouched.

Any other value — including empty or unset — leaves the reporter silent and runs
unchanged, so passing the variable through a container's environment with an
empty default won't switch it on by accident. The reporter is registered
automatically as a Minitest plugin — no setup required.

See [`example/treat_dispenser_feature_test.rb`](example/treat_dispenser_feature_test.rb)
for a complete, runnable example starring Dennis the dachshund:

```bash
STORY=1 ruby -Ilib example/treat_dispenser_feature_test.rb
```

### Using it with Rails system tests

The DSL is framework-agnostic — it only needs a Minitest test class. To use it
for Rails feature/system tests, include it in your base class:

```ruby
class FeatureTestCase < ApplicationSystemTestCase
  include Minitest::Tails
end
```

Rails registers its own reporter, which prints a dot per test alongside the
inline failure output and the `bin/rails test path:line` rerun snippets. Under
`STORY=1` the dots go and the rest of it stays.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run
`rake` to run the tests and the linter. You can also run `bin/console` for an
interactive prompt.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/sebjacobs/minitest-tails. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to adhere
to the [code of conduct](CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
