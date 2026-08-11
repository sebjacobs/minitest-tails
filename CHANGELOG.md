## [Unreleased]

## [0.1.2] - 2026-07-09

- Register the reporter under Minitest 6, which no longer auto-discovers plugins
  via `Gem.find_files` during a run. The gem now self-registers on load
  (`Minitest.register_plugin`), so the reporter attaches on both Minitest 5 and
  6 with no test-suite setup. Previously the reporter silently did nothing under
  Minitest 6 even with `STORY=1`.

## [0.1.1] - 2026-07-09

- Only enable the story reporter when `STORY` is `1` or `true` (case-insensitive).
  Any other value — including empty — leaves it off, so passing the variable
  through a container's environment with an empty default no longer switches it
  on by accident.

## [0.1.0] - 2026-06-23

- Initial release
