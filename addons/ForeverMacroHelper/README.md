# ForeverMacroHelper

Classic Era macro library for the Forever suite. Created by **0xgle**.

**0.2.0-beta1 · English UI and English spell names · Classic Era 1.15.9**

## Install

1. Close WoW. Replace the old `ForeverMacroHelper` folder in `World of Warcraft/_classic_era_/Interface/AddOns/` with this folder.
2. The final path must be `Interface/AddOns/ForeverMacroHelper/ForeverMacroHelper.toc`, without another nested folder.
3. Start WoW, enable the addon in the character-selection AddOns menu, and type `/fmh`.

Saved settings remain in WoW's WTF folder. Do not delete that folder. `INSTALL.bat` opens the usual AddOns directory; it is a folder helper, not an automatic installer.

The minimap launcher is off by default to keep the Forever suite uncluttered. Enable it in `/fmh settings`. Existing saved preferences are preserved.

## Included

- 214 templates covering General and all nine Classic classes, classified as PvE, PvP or Both.
- New generated grimoire artwork and launcher icon, shared Forever control icons, obsidian panels, antique gold and turquoise accents.
- Class and role filters, search, sorting, favorites, editable bodies and per-character saved drafts.
- Create and update character macros. Click or drag the small book beside the editor to place an installed macro on your action bar.
- Class starter packs with a preview, slot preflight and preservation of existing macros. Packs always use your actual character's class, regardless of the browsing filter.
- Character-only macro lookup: account macros are never edited or deleted.
- Exact-body legacy adoption; conflicting names or external edits are preserved and explained.
- Delete confirmation, combat restrictions, byte counter, draggable window and automatic screen-fit scaling.

## Using the library

Select your class and a macro. Read its description and gold requirement note, edit if needed, then choose **Create macro**. Installed macros can be updated individually. Your draft is retained when you switch selection or reload.

**Reset body** restores the curated template in the editor; it does not change the installed macro until you click Update. An external edit made in `/macro` is shown in the editor but is protected from addon overwrites. Rename that macro in `/macro` first if you want to create a fresh Forever version. Account macros with the same name remain separate.

The full library does not occupy game macro slots. Only installed entries consume slots. The client supplies the slot limits; when missing, the addon uses conservative Classic defaults. Pack creation refuses to begin if the missing entries do not fit. A client-side error during creation is reported with the actual completed count.

## Commands

| Command | Action |
| --- | --- |
| `/fmh` or `/forevermacro` | Toggle the library |
| `/fmh pve` | Open with PvE filter |
| `/fmh pvp` | Open with PvP filter |
| `/fmh settings` | Minimap, General templates, scale and position |
| `/fmh reset` | Reset window position |

## Compatibility and scope

The target is **Classic Era 1.15.9**, including use of appropriate templates on Hardcore characters. Hardcore resurrection rules still apply. Installing templates on a different project or non-English game client is disabled rather than silently installing incompatible spell names. The UI stays English. WoW: Forever compatibility needs a separate check against its actual client and API; this build does not claim it.

This is a curated library, not an assertion that every possible macro combination exists. Some entries need learned spells, specific talents, forms, stances, reagents, weapons or pets. They do not choose rotations or react automatically. You activate the installed macro yourself. Macros remain subject to the global cooldown, range, line of sight and spell conditions. A stance transition may require another keypress. See Blizzard's [macro explanation](https://us.forums.blizzard.com/en/wow/t/macros-essential-information/21139).

English spell names are intentional. Modifier variants require Shift bindings that do not intercept the macro key. Rank-specific templates do not automatically choose ranks. Powershifting, Life Tap and pet/area attacks deserve particular care on Hardcore.

## Validation

The included `Docs/AUDIT.md` records coverage, changes, sources and test limits. Lua was loaded and exercised in a mocked WoW environment, including the UI lifecycle and all 214 detail views. This does **not** replace in-game verification; no live game session was available. `Docs/TEST-IN-GAME.md` gives the short test pass.

© 2026 0xgle. All rights reserved.
