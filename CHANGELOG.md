## [Unreleased]

## [0.1.1] - 2026-07-09

- Only enable the story reporter when `STORY` is `1` or `true` (case-insensitive).
  Any other value — including empty — leaves it off, so passing the variable
  through a container's environment with an empty default no longer switches it
  on by accident.

## [0.1.0] - 2026-06-23

- Initial release
