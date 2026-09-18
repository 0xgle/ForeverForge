# ForeverBags 1.0.0

First stable public release for World of Warcraft: Forever.

## Features
- Unified inventory with modern category-based layout.
- Backpack, equipped bags and dedicated reagent bag support.
- Search, filtering and multiple sorting modes.
- Favorites and custom Keep / Sell / Bank tags.
- Item-level, stack-count, quality and lock-state presentation.
- Empty-slot interaction for normal drag and drop.
- Item cooldown display.
- Character inventory snapshots and cross-character ownership tooltips.
- Discovery journal and merchant junk value tools.
- Minimap launcher and configurable UI.

## Compatibility and stability
- Uses the modern `C_Container` API first with legacy container fallbacks where available.
- Player bag range is derived from Blizzard constants rather than hard-coded to four bags.
- Supports the reagent bag as part of the normal player inventory.
- Live item actions are delegated to Blizzard's native container item-button path for right-click use, equipment, modified clicks and drag/drop.
- ForeverBags does not replace, scan or interact with the bank in the stable release; the native WoW bank remains untouched.
- Direct protected item-use calls are not used by the ForeverBags inventory grid.
