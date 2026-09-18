# Validation record — 1.0.3-rc4

## Automated checks

24 scenarios passed under system Lua 5.4 with a finite mock of the WoW frame and
addon APIs. Source code is written using Lua 5.1-compatible constructs. This
run does not certify WoW API signatures or protected execution in the client.

Covered: Core self-protection; dependency enable and dependent-disable closure;
missing dependency rejection; combat guards; apply/undo; injected API failure
and rollback; profile round-trip; invalid/code/duplicate/oversized import
rejection; duplicate profile names; atomic profile conflicts; missing imported
addons; slash launcher discovery; isolated callback failure; construction and
refresh of all six UI pages; widget reuse; nested dialogs; report privacy;
minimap/slash/scale operations; per-addon minimap icon overrides; minimap icon manager widget reuse; legacy enable-state argument order; search and
pagination hiding stale rows.

The log deliberately includes injected errors to verify handling. They are not
observed WoW failures. See DeveloperTools/Tests in the release archive.

Six page layouts were rendered from their actual mocked Lua widget trees and
visually inspected at the base window size. Substitute fonts were used. The
mock cannot validate WoW texture layers, exact text metrics, hardware scaling,
combat taint or third-party addon behavior.

## In-game acceptance checklist — pending

- Cold login with only ForeverCore, then with ForeverBags and ForeverGather.
- `/fc`, minimap left/right click, drag, Escape, logout/login position persistence.
- With several addon launchers installed: verify default hiding, allow one icon, reset it to default, then test global show/hide.
- Verify all textures load and no labels overlap at UI scales 0.65, 1.0 and 1.25.
- Set and use a key binding via WoW's own Key Bindings panel.
- Launch Bags, Bags Config and Gather; test any legacy slash launchers installed.
- Favorite, search, switch scopes and paginate more than five addons.
- Disable a test addon, inspect Review, Apply and Reload; re-enable it.
- Verify a required dependency is included in the review before changing it.
- Save two profiles; export/import a renamed copy; Stage, Apply, Reload.
- Confirm switching profiles affects this character, not another character.
- Confirm combat blocks apply/reload/launch and allows them after combat ends.
- Sample memory, copy the report, Core-only mode and Undo last apply.
- Verify repeated open/close, scrolling a long import and absence of Lua errors.

Ship a stable tag only after recording the exact tested client build and
finishing these checks. The Forever client needs separate validation.
