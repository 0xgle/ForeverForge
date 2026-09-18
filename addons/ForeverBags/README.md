# ForeverBags

ForeverBags is a modern inventory replacement built for **World of Warcraft: Forever** by **0xgle**.

## What it does

ForeverBags combines the player's backpack, equipped bags and reagent bag into a single searchable inventory while keeping a custom visual design. It includes categories, sorting, favorites, custom tags, empty-slot handling, item cooldowns, ownership information, discoveries and merchant utilities.

## WoW Forever API strategy

ForeverBags targets the modern container model used by WoW Forever: it prefers `C_Container`, derives the number of equipped player bags from Blizzard constants and includes the reagent bag when exposed by the client. A legacy fallback layer remains for container reads so the addon does not depend on one branch-specific global API.

For live inventory interaction, ForeverBags uses Blizzard's `ContainerFrameItemButtonTemplate` path rather than issuing protected item-use calls itself. The visual layer is custom to ForeverBags; the underlying click/drag behavior is left to Blizzard's item-button implementation.

## Bank

The stable release intentionally leaves the bank completely to the native WoW interface. ForeverBags neither replaces nor scans the live bank UI.

## Commands

- `/fb` — toggle ForeverBags
- `/fb settings` — open settings
- `/fb containers` — print detected player container IDs and sizes
- `/fb version` — print addon/client diagnostics
- `/fb bank` — reminder that the native WoW bank is used

## Author

0xgle — © 2026. All rights reserved.
