## [Unreleased]

- Add `step_` as an alias of `step`, so a scenario can carry the trailing
  underscore on every step method rather than on all but one.
- Separate each phase of a printed story with a blank line, keeping `And` and
  `But` attached to the step they continue.
- Mark each step in the printed story with the ✓/✗ it already carried in the
  failure narrative, so a failed run shows which step broke without reading down
  to the summary.

## [0.1.3] - 2026-08-11

- Load the gem root from the plugin when Minitest calls the init hook rather than
  when the plugin file is read. The two files required each other, so whichever
  loaded first saw a half-defined `Minitest::Tails`.
- Add `Minitest::Tails.plugin_enabled?`, which holds the whole question of
  whether the reporter should attach — the names it reads (`PLUGIN_ENV_VARS`, so
  either `TAILS` or `STORY`) and the values that count as "on" now live together
  in the gem's namespace instead of being split between it and the plugin shim.

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
