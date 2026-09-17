# ForeverMacroHelper 0.1.0-beta — Test Checklist

## Boot
- [ ] Addon appears in the AddOns list.
- [ ] No Lua error on login.
- [ ] `/fmh` opens and closes the main window.
- [ ] Minimap button opens the addon.

## UI
- [ ] Current class is selected on first open.
- [ ] All classes can be browsed.
- [ ] PvE / PvP / All filters work.
- [ ] Role filters work.
- [ ] Search filters immediately.
- [ ] Favorites persist through `/reload`.
- [ ] Sort cycles A-Z / Role / PvE-PvP.
- [ ] Window position persists.
- [ ] Scale controls work.

## Macro engine
- [ ] Create installs a character macro.
- [ ] Re-clicking Create updates instead of duplicating.
- [ ] Edited body is installed.
- [ ] >255 characters disables Create.
- [ ] Delete removes the selected installed macro.
- [ ] PvE Pack installs only current class + General recommended macros.
- [ ] PvP Pack installs only current class + General recommended macros.
- [ ] Recommended respects current mode.
- [ ] Full macro slots fail gracefully.

## Combat lockdown
- [ ] Enter combat with window open.
- [ ] Create/pack buttons disable.
- [ ] No ADDON_ACTION_BLOCKED caused by CreateMacro/EditMacro.
- [ ] Buttons restore after combat.

## Class smoke tests
- [ ] Warrior
- [ ] Paladin
- [ ] Hunter
- [ ] Rogue
- [ ] Priest
- [ ] Mage
- [ ] Warlock
- [ ] Druid
- [ ] Shaman
