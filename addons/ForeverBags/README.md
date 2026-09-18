# ForeverBags 0.9.5-beta4

The bottom of the category sidebar shows the current character's gold, silver and copper in every view. The balance updates on PLAYER_MONEY and when opening or refreshing the window.

ForeverBags is an inventory addon by 0xgle. This visual update is based on the working Classic Era 0.9.4-beta3 package. It preserves its category sidebar, inventory grid and native item interaction while refining the artwork and readability. Other game clients require separate testing.

## Visual update

- Newly generated dark leather/slate window artwork with restrained brass trim.
- Softer teal selection, category counters and consistent hover states.
- Larger visible item artwork within unchanged slot sizes.
- Border-only item hover: no opaque generated graphic over item icons.
- Two-line merchant stats, readable section counters and quieter empty slots.
- Creator credit `by 0xgle` retained.

Lua 5.1 syntax and mocked UI checks passed. The addon has not been run inside WoW for this update; complete the in-game checklist before publishing a stable release.

**Created and developed by 0xgle.**  
**© 2026 0xgle. All rights reserved.**

## Install

1. Extract the `ForeverBags` folder into the active game client's `Interface/AddOns/` folder.
2. Make sure the final path is `.../Interface/AddOns/ForeverBags/ForeverBags.toc`.
3. Start WoW, open AddOns on the character screen, enable ForeverBags.
4. The package retains interface declarations `120100`, `120001` and `11509` from its base version. A TOC declaration or **Load out of date AddOns** alone does not guarantee compatibility with a different client.
5. In game use `/fb`. By default ForeverBags also captures the normal WoW backpack button and the player's existing bag key (usually `B`) without permanently rewriting the keybind.

There is also an `INSTALL.bat` helper in the release archive.

## Main controls

- `/fb` — toggle the inventory.
- `/fb settings` — settings.
- `/fb bank` — open the bank view.
- `/fb reset` — reset the window position.
- Left-click the small star corner — favorite/unfavorite an item.
- Right-click the small star corner — cycle `Keep → Sell → Bank → None` tag.
- Right-click a live bag item — use it through Blizzard's native container-item handler.
- Left-click / drag a live bag item — pick it up / move it through Blizzard's native container-item handler.
- Shift-click and stack splitting use Blizzard's standard container-item path.
- The normal WoW backpack button and the existing bag key (usually `B`) toggle ForeverBags. This integration can be disabled in `/fb settings`.
- At a merchant, **Sell Junk** sells poor-quality vendorable items. Shift-clicking the button also includes items manually tagged `Sell`. Favorites and `Keep` items are never sold.

## Search syntax

Plain text searches names/types. Power filters can be mixed with text:

- `q:epic`, `q:4`
- `type:weapon`
- `bag:0`
- `count:>=5`
- `ilvl:>40`
- `fav:true`
- `new:true`
- `tag:keep`
- `id:12345`

Quoted phrases are supported.

## Architecture

The addon is dependency-free and split into a compatibility API layer, event-driven data model, cached SavedVariables storage, search engine, feature modules and pooled UI components. Live inventory interaction is delegated to Blizzard's `ContainerFrameItemButtonTemplate` instead of directly calling protected use/pickup functions from ForeverBags. It does not include or copy Bagnon/BetterBags source code; its implementation is independent.

## Beta note

WoW: Forever is still in beta. Blizzard can change container/bank APIs or UI restrictions. ForeverBags intentionally keeps those calls behind `Core/Compat.lua`, so client-specific fixes should stay isolated there instead of forcing a rewrite of the UI.
