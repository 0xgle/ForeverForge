# Changelog

## 0.9.5-beta2 — player money

- Added a permanent current-character balance below the category list, separate from junk sale value.
- Shows gold, silver and copper, including a zero balance, in every view.
- Updates immediately on PLAYER_MONEY and on window refresh.

## 0.9.5-beta1 — visual polish

- Added generated vault panel artwork, brass accents and subdued teal selection.
- Preserved window geometry, category order, grid, bag controls and native click handling.
- Added category counters reflecting the current search (counts of displayed item entries, not stack quantities).
- Improved section headings, footer stats, settings credits and focus feedback.
- Increased visible icon area; replaced opaque hover artwork with a mouse-transparent border.
- Kept merchant, saved data, bag integration and item action logic unchanged.
- Passed Lua 5.1 syntax and mocked UI tests; real-client validation remains required.

## 0.9.4-beta3
- Moved **Sell Junk** into the bottom footer so it can no longer overlap inventory section bars or item rows.
- Footer stats automatically shift left while **Sell Junk** is visible and return to the right edge when the merchant closes.
- Repositioned the visible **by 0xgle** signature beside the ForeverBags title so it stays readable and clear of the search bar.
- Keeps the working Classic Era native item interaction from 0.9.4-beta1/beta2 unchanged.

## 0.9.4-beta2
- Added visible creator credit for 0xgle in the main UI, settings, minimap tooltip, addon metadata, README, and license.
- Updated copyright notice to © 2026 0xgle. All rights reserved.
- Keeps the Classic Era native item-click fix from 0.9.4-beta1 unchanged.

## 0.9.4-beta1 — 2026-09-17

- Fixed Classic Era live item buttons not reacting to mouse input.
- Explicitly shows the inherited Blizzard `ContainerFrameItemButtonTemplate` while keeping it visually transparent under ForeverBags art.
- Seeds `SetBagID`, `bagID`, slot ID and supports both `Init()` and `Initialize()` style shared-container initializers.
- Native slot is hidden again when detached, preventing invisible stale click targets.

## 0.9.3-beta1 — 2026-09-17

- Added a dedicated Classic Era 1.15.9 native path.
- Normal Blizzard backpack button, equipped bag buttons and the normal bag key now route through the same bag API entry points used by mature bag replacements instead of a UI overlay/temporary keybinding.
- Rebuilt live item interaction around one persistent Blizzard `ContainerFrameItemButtonTemplate` per physical bag slot.
- Native slots now use a dedicated bag-ID parent and Blizzard `Initialize(bag, slot)` when available, avoiding dynamic slot rebinding and the taint-prone pattern from beta1.
- Prewarms Classic inventory slots outside combat so secure container templates are not created while fighting.
- Added `/fb version` and `/fb native` diagnostics.

## 0.9.2-beta1 — 2026-09-17

- Reworked live item interaction to use Blizzard `ContainerFrameItemButtonTemplate` buttons, following the same broad safe pattern used by mature bag replacements.
- Removed direct live-item `UseContainerItem` / `PickupContainerItem` calls from the ForeverBags item grid to avoid the protected-action / taint popup.
- Added native drag/drop, right-click use, modified-click and stack-split handling through Blizzard's container item scripts.
- Added normal WoW backpack-button integration.
- Added temporary override of the player's existing bag key (usually `B`) so it toggles ForeverBags without permanently rewriting saved keybindings.
- Added a settings toggle for native bag-button/key integration.
- Moved favorite/tag controls to a small dedicated star corner so metadata actions never interfere with native item interaction.
- Added branch-compatibility fields for classic/modern container item templates.

## 0.9.0-beta1 — 2026-09-17

- First release candidate for WoW: Forever beta testing.
- Unified bag inventory.
- Sectioned categories and quick category filters.
- Query parser with quality/type/bag/count/ilvl/favorite/new/tag/id filters.
- Sort by physical bag order, name, rarity, stack size and vendor value.
- Current-character bank snapshot with offline cached bank view.
- Cross-character inventory/bank aggregation.
- Ownership counts added to item tooltips.
- Discovery journal with first-seen time, zone and best-effort loot source.
- Favorites and Keep/Sell/Bank tags.
- Safe Sell Junk queue that protects favorites and Keep-tagged items.
- Custom generated fantasy UI icon/media set.
- Minimap launcher, key binding and settings panel.
- API compatibility layer for modern C_Container and legacy fallbacks.
