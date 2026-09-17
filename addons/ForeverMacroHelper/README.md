# ForeverMacroHelper

**ForeverMacroHelper** is a Classic Era macro library and one-click macro installer for the Forever addon suite.

Created by **0xgle**. © 2026 0xgle. All rights reserved.

## Version

0.1.0-beta — Classic Era 1.15.9

## What is included

- 133 curated macros.
- Every Classic class: Warrior, Paladin, Hunter, Rogue, Priest, Mage, Warlock, Druid and Shaman.
- General macros shared across characters.
- PvE, PvP and dual-purpose classification.
- Role filters: Offense, Defense, Healing, CC, Utility, Pet and Targeting.
- Search across titles, descriptions, tags and macro body.
- Sort by name, role or PvE/PvP type.
- Favorites.
- Editable macro body before installation.
- One-click Create / Update.
- Recommended PvE, PvP and current-filter packs.
- Per-character installation to avoid mixing class libraries.
- Existing ForeverMacroHelper macros are updated instead of duplicated.
- Macro character counter with the Classic 255-character limit.
- Combat lockdown protection: macro creation/editing is disabled in combat.
- Minimap launcher, movable window and UI scale controls.
- `/fmh`, `/fmh pve`, `/fmh pvp`, `/fmh settings`, `/fmh reset`.

## Installation

Copy the `ForeverMacroHelper` folder into:

`World of Warcraft/_classic_era_/Interface/AddOns/`

Restart WoW or reload the UI, then type `/fmh`.

## Recommended workflow

1. Open `/fmh`.
2. Your current class is selected automatically.
3. Choose PvE or PvP.
4. Install individual macros, or use a Recommended Pack.
5. Drag the newly created macros from the normal WoW Macro window to your bars.

## Important Classic limitation

World of Warcraft does not allow addons to create or edit macros while the player is in combat. ForeverMacroHelper disables installation buttons during combat and re-enables them afterwards.

The game also limits available macro slots, so the addon keeps the full library inside the addon and installs only the macros you actually want. Recommended class packs are intentionally kept compact.

## Beta test priorities

- Confirm macro creation and update on Classic Era 1.15.9.
- Confirm the question-mark macro icon is accepted on the current client build.
- Validate every class macro on an appropriate character/talent setup.
- Check UI at 0.8–1.25 scale and common resolutions.
- Check that opening the addon during combat never causes blocked-action errors.

