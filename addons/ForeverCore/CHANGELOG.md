# ForeverCore Changelog

## 1.0.3-rc4
- Added an inline Minimap checkbox to each row in Your Addons.
- The checkbox reuses the existing per-addon minimap visibility system, so it stays synchronized with Appearance > Minimap addon icons.
- ForeverCore launcher visibility can now be toggled from its own addon row as well.
- Rows without a detected or previously managed minimap launcher show the control as unavailable instead of creating a fake setting.

## 1.0.2-rc3
- Added per-addon minimap icon control: keep all third-party launchers hidden by default, then allow selected addon icons individually.
- Added a dedicated Minimap addon icons manager in Appearance and `/fc icons`.
- Added rescanning after delayed addon loads so late-created LibDBIcon/LDB launchers are picked up.
- Core minimap artwork now uses transparency so the square dark background is removed.

## 1.0.1-rc2
- Minimap cleanup is enabled by default: ForeverCore keeps its own launcher and hides detected third-party addon minimap buttons.
- Added Appearance toggle for third-party minimap icons.
- Added `/fc icons` quick toggle.
- Re-scans shortly after login to catch late-created LibDataBroker/LibDBIcon launchers.
- Blizzard minimap controls are excluded from cleanup.

## 1.0.0-rc1

First release candidate of ForeverCore — The Sanctum.

- Six-page command center with original gold and turquoise fantasy artwork.
- Addon detection, search, favorites and quick launch.
- Explicit dependency-aware change review, per-character application and reload.
- Current-session callback diagnostics, memory samples and activity history.
- Named loadouts, bounded safe text import/export and last-apply undo.
- Built-in ForeverBags/ForeverGather launch adapters and legacy slash discovery.
- Optional module registration API and optional existing-LibDataBroker support.
- Minimap launcher, user-bindable shortcut and screen-fit scaling.
- Installation documentation, source tests and visual layout previews.

Requires final acceptance testing in Classic Era. No tested Forever-client claim.
