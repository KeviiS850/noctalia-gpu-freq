# Changelog

All notable changes to `gpu-freq` are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
adheres to [Semantic Versioning](https://semver.org/).

## [0.2.0] — 2026-07-22

### Fixed
- **Bar widget rendered without a glyph**: `icon: "gpu"` does not exist in
  Noctalia's tabler icon set, causing the pill to show an empty icon slot
  on some themes. Switched to `icon: "device-desktop"`, the existing tabler
  alias also used by Noctalia's built-in `gpu-temperature` widget.
- **Per-instance settings dialog has nothing to display**: added
  `PluginSettings.qml` entry point so right-click → Settings opens a
  proper toggles form (showUtil/showMax/showMin/showBoost/gpuCard/autoDetectCard).
- **Defensive sysfs reads**: `Main.qml` now parses with a strict
  integer-safe helper, coercing empty/unparseable values to `0` and
  displaying `"?"` for unused labels. Polls at 1500 ms with triggered-on-start
  so the first frame has real data.
- **Force-open flag**: `BarPill { forceOpen: true }` prevents a 0-width
  flicker on transient empty values.

### Added
- `panel` entry point → Panel.qml re-enabled.
- `widgetSettings` entry point → PluginSettings.qml surfaces plugin preferences
  in the bar widget's right-click menu.
- `autoDetectCard` setting (default true) — declarative placeholder for
  future auto-detection logic.
- `pollIntervalMs` setting (default 1500) for tweaking the polling cadence.
- `.gitignore` to exclude `.qml.cache/`, backups, and IDE cruft.
- `CHANGELOG.md` (this file).

### Changed
- Bumped `version` to `0.2.0` in `manifest.json`.
- `homepage` corrected to `KeviiS850/noctalia-gpu-freq` (matching the actual repo URL).
- Added `license` and `tags` fields to `manifest.json`.
- README `/Compatibility` table replaced with the v0.2.0 support matrix.
- Backup directory layout now includes v0.1.3-pre-v0.2.0 snapshots.

## [0.1.3] — 2026-07-21

- Switched to `BarPill` base component for visibility.
- Wildcard udev rule (`card[0-9]*`).
- Idempotent installer with message UX improvements.
- Robust widget sizing.

## [0.1.1] — 2025-07-16

- Compact-mode-only widget (panel component removed).
- Configurable `gpuCard`.
- Manifest cleanup.

## [0.1.0] — 2025-07-16

- Initial release.
- Bar widget with utilization % + active frequency.
- Panel with live graph, history tooltips, status badge.
- Display-mode toggles.
