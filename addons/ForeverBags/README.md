# ForeverBags 0.9.0-beta1

ForeverBags is an original premium inventory replacement built for testing with World of Warcraft: Forever and compatible modernized WoW clients. It combines a unified inventory grid, fast search, category filtering, bank caching, cross-character ownership, item discoveries, item tags, favorites, merchant junk selling and a custom generated visual system.

## Install

1. Extract the `ForeverBags` folder into the active game client's `Interface/AddOns/` folder.
2. Make sure the final path is `.../Interface/AddOns/ForeverBags/ForeverBags.toc`.
3. Start WoW, open AddOns on the character screen, enable ForeverBags.
4. If the Forever beta uses a new TOC number, tick **Load out of date AddOns**. The package currently declares interface versions `120100`, `120001` and `11509` because Blizzard has not published a dedicated Forever beta TOC number publicly yet.
5. In game use `/fb` or assign **ForeverBags → Toggle inventory** in Key Bindings > AddOns.

There is also an `INSTALL.bat` helper in the release archive.

## Main controls

- `/fb` — toggle the inventory.
- `/fb settings` — settings.
- `/fb bank` — open the bank view.
- `/fb reset` — reset the window position.
- Middle-click an item — favorite/unfavorite it.
- Alt + Right-click — cycle `Keep → Sell → Bank → None` tag.
- Right-click a live bag item — use it.
- Left-click a live bag item — pick it up / move it.
- Shift-click — lets Blizzard handle the standard modified item action.
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

The addon is dependency-free and split into a compatibility API layer, event-driven data model, cached SavedVariables storage, search engine, feature modules and pooled UI components. It does not include or copy Bagnon/BetterBags source code. Its functionality is independently implemented.

## Beta note

WoW: Forever is still in beta. Blizzard can change container/bank APIs or UI restrictions. ForeverBags intentionally keeps those calls behind `Core/Compat.lua`, so client-specific fixes should stay isolated there instead of forcing a rewrite of the UI.
